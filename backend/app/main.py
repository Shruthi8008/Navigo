from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import Settings, settings
from app.db import Database
from app.schemas import (
    AuthResponse,
    FavoritePlaceRequest,
    FavoritePlaceResponse,
    FavoritePlacesResponse,
    LoginRequest,
    PlaceSafetyRatingRequest,
    RoadSafetyRatingRequest,
    RoadSafetySummaryRequest,
    RouteRequest,
    RouteResponse,
    SafetyCommentRequest,
    SafetyCommentsResponse,
    SafetyCommentResponse,
    SafetySummaryResponse,
    SearchResponse,
    SignupRequest,
    UserResponse,
)
from app.services.auth_service import AuthService, AuthServiceError
from app.services.community_service import CommunityService, CommunityServiceError
from app.services.mapping_service import MappingService, MappingServiceError
from app.services.routing_provider import GraphHopperRoutingProvider
from app.security import decode_access_token

database = Database(settings)
mapping_service = MappingService(
    GraphHopperRoutingProvider(settings),
    settings,
    database,
)
security = HTTPBearer(auto_error=False)


@asynccontextmanager
async def lifespan(_: FastAPI):
    await database.connect()
    yield
    await database.disconnect()


app = FastAPI(title="Secmap API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_settings() -> Settings:
    return settings


def get_mapping_service(
    _: Settings = Depends(get_settings),
) -> MappingService:
    return mapping_service


def get_auth_service(
    app_settings: Settings = Depends(get_settings),
) -> AuthService:
    return AuthService(database, app_settings)


def get_community_service() -> CommunityService:
    return CommunityService(database)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    auth_service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Authentication required.")

    try:
        payload = decode_access_token(credentials.credentials, settings)
        user_id = int(payload["sub"])
    except (ValueError, KeyError):
        raise HTTPException(status_code=401, detail="Invalid or expired token.")

    user = await auth_service.get_user_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="User session is no longer valid.")
    return user


@app.post(
    "/auth/signup",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
)
async def signup(
    request: SignupRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    try:
        return await service.signup(request)
    except AuthServiceError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@app.post("/auth/login", response_model=AuthResponse)
async def login(
    request: LoginRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    try:
        return await service.login(request)
    except AuthServiceError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error


@app.get("/search", response_model=SearchResponse)
async def search_places(
    query: str = Query(min_length=2),
    service: MappingService = Depends(get_mapping_service),
) -> SearchResponse:
    try:
        suggestions = await service.search_places(query)
    except MappingServiceError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error

    return SearchResponse(suggestions=suggestions)


@app.post("/route", response_model=RouteResponse)
async def route_between_points(
    request: RouteRequest,
    service: MappingService = Depends(get_mapping_service),
) -> RouteResponse:
    try:
        return await service.build_route(
            request.source,
            request.destination,
            route_type="shortest",
        )
    except MappingServiceError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error


@app.post("/route/shortest", response_model=RouteResponse)
async def shortest_route_between_points(
    request: RouteRequest,
    service: MappingService = Depends(get_mapping_service),
) -> RouteResponse:
    try:
        return await service.build_route(
            request.source,
            request.destination,
            route_type="shortest",
        )
    except MappingServiceError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error


@app.post("/route/safest", response_model=RouteResponse)
async def safest_route_between_points(
    request: RouteRequest,
    service: MappingService = Depends(get_mapping_service),
) -> RouteResponse:
    try:
        return await service.build_route(
            request.source,
            request.destination,
            route_type="safest",
        )
    except MappingServiceError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error


@app.post("/community/place-ratings", response_model=SafetySummaryResponse)
async def add_place_rating(
    request: PlaceSafetyRatingRequest,
    user: UserResponse = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> SafetySummaryResponse:
    try:
        return await service.add_place_rating(user, request)
    except CommunityServiceError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@app.get("/community/place-ratings", response_model=SafetySummaryResponse)
async def get_place_rating(
    latitude: float,
    longitude: float,
    service: CommunityService = Depends(get_community_service),
) -> SafetySummaryResponse:
    return await service.get_place_safety_summary(latitude, longitude)


@app.post("/community/road-ratings", response_model=SafetySummaryResponse)
async def add_road_rating(
    request: RoadSafetyRatingRequest,
    user: UserResponse = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> SafetySummaryResponse:
    try:
        return await service.add_road_rating(user, request)
    except CommunityServiceError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@app.post("/community/road-ratings/summary", response_model=SafetySummaryResponse)
async def get_road_rating(
    request: RoadSafetySummaryRequest,
    service: CommunityService = Depends(get_community_service),
) -> SafetySummaryResponse:
    return await service.get_road_safety_summary(request.route_points)


@app.post("/community/comments", response_model=SafetyCommentResponse)
async def add_comment(
    request: SafetyCommentRequest,
    user: UserResponse = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> SafetyCommentResponse:
    try:
        return await service.add_comment(user, request)
    except CommunityServiceError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@app.get("/community/comments", response_model=SafetyCommentsResponse)
async def list_comments(
    target_type: str,
    target_key: str,
    service: CommunityService = Depends(get_community_service),
) -> SafetyCommentsResponse:
    comments = await service.list_comments(target_type, target_key)
    return SafetyCommentsResponse(comments=comments)


@app.post("/community/favorites", response_model=FavoritePlaceResponse)
async def add_favorite_place(
    request: FavoritePlaceRequest,
    user: UserResponse = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> FavoritePlaceResponse:
    try:
        return await service.add_favorite_place(user, request)
    except CommunityServiceError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@app.delete("/community/favorites", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite_place(
    latitude: float,
    longitude: float,
    user: UserResponse = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> None:
    await service.remove_favorite_place(user.id, latitude, longitude)


@app.get("/community/favorites", response_model=FavoritePlacesResponse)
async def list_favorite_places(
    user: UserResponse = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> FavoritePlacesResponse:
    favorites = await service.list_favorite_places(user.id)
    return FavoritePlacesResponse(favorites=favorites)


@app.get("/community/comments/me", response_model=SafetyCommentsResponse)
async def list_my_comments(
    user: UserResponse = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> SafetyCommentsResponse:
    comments = await service.list_user_comments(user.id)
    return SafetyCommentsResponse(comments=comments)


@app.get("/community/comments/nearby", response_model=SafetyCommentsResponse)
async def list_nearby_comments(
    latitude: float,
    longitude: float,
    radius_km: float = 0.5,
    service: CommunityService = Depends(get_community_service),
) -> SafetyCommentsResponse:
    comments = await service.list_nearby_comments(latitude, longitude, radius_km)
    return SafetyCommentsResponse(comments=comments)
