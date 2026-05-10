from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

import httpx

from app.config import Settings
from app.schemas import Coordinates
from app.services.route_selection import RouteCandidate


class RoutingProviderError(Exception):
    pass


class RoutingProvider(ABC):
    @abstractmethod
    async def build_route_candidates(
        self,
        source: Coordinates,
        destination: Coordinates,
        *,
        include_alternatives: bool = False,
    ) -> list[RouteCandidate]:
        raise NotImplementedError


class GraphHopperRoutingProvider(RoutingProvider):
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def build_route_candidates(
        self,
        source: Coordinates,
        destination: Coordinates,
        *,
        include_alternatives: bool = False,
    ) -> list[RouteCandidate]:
        params = {
            "key": self._settings.graphhopper_api_key,
            "profile": "car",
            "points_encoded": "false",
            "instructions": "false",
            "calc_points": "true",
        }
        if include_alternatives:
            params.update(
                {
                    "algorithm": "alternative_route",
                    "ch.disable": "true",
                    "alternative_route.max_paths": "3",
                }
            )
        payload = {
            "points": [
                [source.longitude, source.latitude],
                [destination.longitude, destination.latitude],
            ],
            # TODO: Inject GraphHopper custom models here once we have
            # time-aware safety, AI prediction, and heatmap risk layers.
        }

        async with httpx.AsyncClient(
            base_url=self._settings.graphhopper_base_url,
            timeout=15.0,
        ) as client:
            response = await client.post("/route", params=params, json=payload)

        if response.status_code != 200:
            if include_alternatives:
                return await self.build_route_candidates(
                    source,
                    destination,
                    include_alternatives=False,
                )
            raise RoutingProviderError(self._extract_error_message(response))

        data = response.json()
        paths = data.get("paths")
        if not paths:
            raise RoutingProviderError("Unable to draw a route right now.")

        return [
            RouteCandidate(
                points=self._extract_points(path),
                distance_meters=float(path["distance"]),
                duration_seconds=float(path["time"]) / 1000,
            )
            for path in paths
        ]

    def _extract_points(self, path: dict[str, Any]) -> list[Coordinates]:
        raw_points = path.get("points")
        if isinstance(raw_points, dict):
            coordinates = raw_points.get("coordinates")
            if not isinstance(coordinates, list):
                raise RoutingProviderError("Route points are missing from GraphHopper.")

            return [
                Coordinates(latitude=float(lat), longitude=float(lon))
                for lon, lat in coordinates
            ]

        if isinstance(raw_points, str):
            return self._decode_polyline(raw_points)

        raise RoutingProviderError("Unable to parse route points from GraphHopper.")

    def _decode_polyline(self, encoded: str) -> list[Coordinates]:
        index = 0
        latitude = 0
        longitude = 0
        coordinates: list[Coordinates] = []

        while index < len(encoded):
            latitude_change, index = self._decode_polyline_value(encoded, index)
            longitude_change, index = self._decode_polyline_value(encoded, index)
            latitude += latitude_change
            longitude += longitude_change
            coordinates.append(
                Coordinates(
                    latitude=latitude / 1e5,
                    longitude=longitude / 1e5,
                )
            )

        return coordinates

    def _decode_polyline_value(self, encoded: str, index: int) -> tuple[int, int]:
        result = 0
        shift = 0

        while True:
            if index >= len(encoded):
                raise RoutingProviderError("Received an invalid encoded route polyline.")

            value = ord(encoded[index]) - 63
            index += 1
            result |= (value & 0x1F) << shift
            shift += 5

            if value < 0x20:
                break

        decoded = ~(result >> 1) if (result & 1) else (result >> 1)
        return decoded, index

    def _extract_error_message(self, response: httpx.Response) -> str:
        try:
            data = response.json()
        except ValueError:
            return "Unable to draw a route right now."

        message = data.get("message")
        if isinstance(message, str) and message:
            return message

        hints = data.get("hints")
        if isinstance(hints, list) and hints:
            first_hint = hints[0]
            if isinstance(first_hint, dict):
                details = first_hint.get("message")
                if isinstance(details, str) and details:
                    return details

        return "Unable to draw a route right now."
