from __future__ import annotations

from dataclasses import dataclass

from app.schemas import Coordinates, RouteResponse


@dataclass(frozen=True)
class RouteCandidate:
    points: list[Coordinates]
    distance_meters: float
    duration_seconds: float


def choose_safest_route(
    candidates: list[RouteCandidate],
    segment_score_map: dict[str, float],
) -> RouteResponse:
    best_candidate = candidates[0]
    best_cost = _candidate_cost(candidates[0], segment_score_map)

    for candidate in candidates[1:]:
        cost = _candidate_cost(candidate, segment_score_map)
        if cost < best_cost:
            best_candidate = candidate
            best_cost = cost

    matched_scores = _matched_scores(best_candidate, segment_score_map)
    safety_score = (
        sum(matched_scores) / len(matched_scores) if matched_scores else 0.5
    )

    return RouteResponse(
        points=best_candidate.points,
        distanceMeters=best_candidate.distance_meters,
        durationSeconds=best_candidate.duration_seconds,
        routeType="safest",
        safetyScore=round(safety_score, 2),
    )


def choose_shortest_route(candidate: RouteCandidate) -> RouteResponse:
    return RouteResponse(
        points=candidate.points,
        distanceMeters=candidate.distance_meters,
        durationSeconds=candidate.duration_seconds,
        routeType="shortest",
        safetyScore=None,
    )


def _candidate_cost(
    candidate: RouteCandidate,
    segment_score_map: dict[str, float],
) -> float:
    total_cost = 0.0
    for index in range(len(candidate.points) - 1):
        start = candidate.points[index]
        end = candidate.points[index + 1]
        segment_key = _segment_key(start, end)
        score = segment_score_map.get(segment_key, 0.5)

        # TODO: Replace this simple multiplier with time-based safety,
        # AI scoring, and heatmap-derived risk when those data sources exist.
        multiplier = 1.35 - (score * 0.5)
        total_cost += _segment_distance(start, end) * multiplier

    return total_cost


def _matched_scores(
    candidate: RouteCandidate,
    segment_score_map: dict[str, float],
) -> list[float]:
    scores: list[float] = []
    for index in range(len(candidate.points) - 1):
        score = segment_score_map.get(
            _segment_key(candidate.points[index], candidate.points[index + 1]),
        )
        if score is not None:
            scores.append(score)
    return scores


def _segment_key(start: Coordinates, end: Coordinates) -> str:
    first = f"{start.latitude:.5f},{start.longitude:.5f}"
    second = f"{end.latitude:.5f},{end.longitude:.5f}"
    return "|".join(sorted([first, second]))


def _segment_distance(start: Coordinates, end: Coordinates) -> float:
    lat_delta = start.latitude - end.latitude
    lng_delta = start.longitude - end.longitude
    return ((lat_delta * lat_delta) + (lng_delta * lng_delta)) ** 0.5
