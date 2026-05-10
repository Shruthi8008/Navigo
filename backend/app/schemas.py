from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.security import ensure_password_length_for_bcrypt


class Coordinates(BaseModel):
    latitude: float
    longitude: float


class PlaceSuggestionResponse(BaseModel):
    name: str
    address: str
    latitude: float
    longitude: float


class SearchResponse(BaseModel):
    suggestions: list[PlaceSuggestionResponse]


class RouteRequest(BaseModel):
    source: Coordinates
    destination: Coordinates


class RouteResponse(BaseModel):
    points: list[Coordinates]
    distance_meters: float = Field(alias="distanceMeters")
    duration_seconds: float = Field(alias="durationSeconds")
    route_type: str = Field(default="shortest", alias="routeType")
    safety_score: float | None = Field(default=None, alias="safetyScore")


class SignupRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    full_name: str = Field(min_length=2, max_length=120, alias="fullName")
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Full name is required.")
        return cleaned

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        ensure_password_length_for_bcrypt(value)
        return value


class LoginRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        ensure_password_length_for_bcrypt(value)
        return value


class UserResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    full_name: str = Field(alias="fullName")
    email: EmailStr


class AuthResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    access_token: str = Field(alias="accessToken")
    token_type: str = Field(alias="tokenType")
    user: UserResponse


class RouteTypeResponse(BaseModel):
    route_type: str = Field(alias="routeType")
    title: str
    description: str


class FavoritePlaceRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    place_name: str = Field(alias="placeName", min_length=1, max_length=255)
    address: str = Field(min_length=1, max_length=500)
    latitude: float
    longitude: float


class FavoritePlaceResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    place_name: str = Field(alias="placeName")
    address: str
    latitude: float
    longitude: float
    is_favorite: bool = Field(default=True, alias="isFavorite")


class FavoritePlacesResponse(BaseModel):
    favorites: list[FavoritePlaceResponse]


class SafetyLevel(str):
    SAFE = "safe"
    MODERATE = "moderate"
    UNSAFE = "unsafe"


class PlaceSafetyRatingRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    place_name: str = Field(alias="placeName", min_length=1, max_length=255)
    address: str = Field(min_length=1, max_length=500)
    latitude: float
    longitude: float
    rating: str
    comment: str | None = Field(default=None, max_length=1000)

    @field_validator("rating")
    @classmethod
    def validate_rating(cls, value: str) -> str:
      lowered = value.lower()
      if lowered not in {"safe", "moderate", "unsafe"}:
        raise ValueError("Rating must be safe, moderate, or unsafe.")
      return lowered


class RoadSafetyRatingRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    route_points: list[Coordinates] = Field(alias="routePoints", min_length=2)
    rating: str
    comment: str | None = Field(default=None, max_length=1000)

    @field_validator("rating")
    @classmethod
    def validate_rating(cls, value: str) -> str:
      lowered = value.lower()
      if lowered not in {"safe", "moderate", "unsafe"}:
        raise ValueError("Rating must be safe, moderate, or unsafe.")
      return lowered


class SafetySummaryResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    normalized_score: float = Field(alias="normalizedScore")
    safety_badge: str = Field(alias="safetyBadge")
    total_ratings_count: int = Field(alias="totalRatingsCount")
    average_label: str = Field(alias="averageLabel")


class SafetyCommentRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    target_type: str = Field(alias="targetType")
    target_key: str = Field(alias="targetKey")
    place_name: str | None = Field(default=None, alias="placeName", max_length=255)
    address: str | None = Field(default=None, max_length=500)
    latitude: float | None = None
    longitude: float | None = None
    comment: str = Field(min_length=2, max_length=1000)

    @field_validator("target_type")
    @classmethod
    def validate_target_type(cls, value: str) -> str:
        lowered = value.lower()
        if lowered not in {"place", "route"}:
            raise ValueError("targetType must be place or route.")
        return lowered


class SafetyCommentResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    user_name: str = Field(alias="userName")
    target_type: str = Field(alias="targetType")
    target_key: str = Field(alias="targetKey")
    comment: str
    created_at: str = Field(alias="createdAt")
    place_name: str | None = Field(default=None, alias="placeName")
    address: str | None = Field(default=None)
    latitude: float | None = None
    longitude: float | None = None


class SafetyCommentsResponse(BaseModel):
    comments: list[SafetyCommentResponse]


class RoadSafetySummaryRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    route_points: list[Coordinates] = Field(alias="routePoints", min_length=2)
