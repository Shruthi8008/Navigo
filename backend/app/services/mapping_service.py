from __future__ import annotations

import httpx

from app.cache import TtlCache
from app.config import Settings
from app.db import Database
from app.schemas import Coordinates, PlaceSuggestionResponse, RouteResponse
from app.services.route_selection import choose_safest_route, choose_shortest_route
from app.services.routing_provider import RoutingProvider, RoutingProviderError


class MappingServiceError(Exception):
    pass


class MappingService:
    def __init__(
        self,
        routing_provider: RoutingProvider,
        settings: Settings,
        database: Database,
    ) -> None:
        self._routing_provider = routing_provider
        self._database = database
        self._search_cache: TtlCache[list[PlaceSuggestionResponse]] = TtlCache(
            ttl_seconds=settings.search_cache_ttl_seconds,
        )
        self._route_cache: TtlCache[RouteResponse] = TtlCache(
            ttl_seconds=settings.route_cache_ttl_seconds,
        )

    async def search_places(self, query: str) -> list[PlaceSuggestionResponse]:
        normalized_query = query.strip().lower()
        cached_results = self._search_cache.get(normalized_query)
        if cached_results is not None:
            return cached_results

        params = {
            "q": query,
            "format": "jsonv2",
            "limit": 6,
            "addressdetails": 1,
        }
        headers = {
            "User-Agent": "secmap-backend/1.0",
            "Accept": "application/json",
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params=params,
                headers=headers,
            )

        if response.status_code != 200:
            raise MappingServiceError("Unable to search places right now.")

        results = response.json()
        suggestions: list[PlaceSuggestionResponse] = []
        for item in results:
            display_name = (item.get("display_name") or "").strip()
            name = display_name.split(",")[0].strip() if display_name else "Unknown place"
            suggestions.append(
                PlaceSuggestionResponse(
                    name=name,
                    address=display_name,
                    latitude=float(item["lat"]),
                    longitude=float(item["lon"]),
                )
            )

        self._search_cache.set(normalized_query, suggestions)
        return suggestions

    async def build_route(
        self,
        source: Coordinates,
        destination: Coordinates,
        route_type: str = "shortest",
    ) -> RouteResponse:
        cache_key = (
            f"{route_type}|"
            f"{source.latitude:.6f},{source.longitude:.6f}|"
            f"{destination.latitude:.6f},{destination.longitude:.6f}"
        )
        cached_route = self._route_cache.get(cache_key)
        if cached_route is not None:
            return cached_route

        try:
            route = await self._select_route(source, destination, route_type)
        except RoutingProviderError as error:
            raise MappingServiceError(str(error)) from error

        self._route_cache.set(cache_key, route)
        return route

    async def _select_route(
        self,
        source: Coordinates,
        destination: Coordinates,
        route_type: str,
    ) -> RouteResponse:
        include_alternatives = route_type == "safest"
        candidates = await self._routing_provider.build_route_candidates(
            source,
            destination,
            include_alternatives=include_alternatives,
        )
        if not candidates:
            raise RoutingProviderError("Unable to draw a route right now.")

        if route_type != "safest":
            return choose_shortest_route(candidates[0])

        segment_score_map = await self._load_segment_scores_for_candidates(candidates)
        return choose_safest_route(candidates, segment_score_map)

    async def _load_segment_scores_for_candidates(self, candidates) -> dict[str, float]:
        segment_keys: set[str] = set()
        for candidate in candidates:
            for index in range(len(candidate.points) - 1):
                start = candidate.points[index]
                end = candidate.points[index + 1]
                first = f"{start.latitude:.5f},{start.longitude:.5f}"
                second = f"{end.latitude:.5f},{end.longitude:.5f}"
                segment_keys.add("|".join(sorted([first, second])))

        if not segment_keys:
            return {}

        placeholders = ", ".join(["%s"] * len(segment_keys))
        query = f"""
        SELECT segment_key, normalized_score
        FROM road_segment_safety_scores
        WHERE segment_key IN ({placeholders})
        """

        async with self._database.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(query, tuple(segment_keys))
                rows = await cursor.fetchall()

        return {str(row[0]): float(row[1]) for row in rows}
