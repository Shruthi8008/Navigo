from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    graphhopper_api_key: str = Field(alias="GRAPHHOPPER_API_KEY")
    graphhopper_base_url: str = "https://graphhopper.com/api/1"
    mysql_host: str = Field(alias="MYSQL_HOST")
    mysql_port: int = Field(default=3306, alias="MYSQL_PORT")
    mysql_user: str = Field(alias="MYSQL_USER")
    mysql_password: str = Field(alias="MYSQL_PASSWORD")
    mysql_database: str = Field(alias="MYSQL_DATABASE")
    jwt_secret_key: str = Field(alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_access_token_expire_minutes: int = Field(
        default=60 * 24,
        alias="JWT_ACCESS_TOKEN_EXPIRE_MINUTES",
    )
    search_cache_ttl_seconds: int = Field(
        default=300,
        alias="SEARCH_CACHE_TTL_SECONDS",
    )
    route_cache_ttl_seconds: int = Field(
        default=120,
        alias="ROUTE_CACHE_TTL_SECONDS",
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
