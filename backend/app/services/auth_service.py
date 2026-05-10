from __future__ import annotations

from datetime import timedelta

from aiomysql import DictCursor

from app.config import Settings
from app.db import Database
from app.schemas import AuthResponse, LoginRequest, SignupRequest, UserResponse
from app.security import create_access_token, hash_password, verify_password


class AuthServiceError(Exception):
    pass


class AuthService:
    def __init__(self, database: Database, settings: Settings) -> None:
        self._database = database
        self._settings = settings

    async def signup(self, request: SignupRequest) -> AuthResponse:
        existing_user = await self._get_user_by_email(request.email)
        if existing_user is not None:
            raise AuthServiceError("An account with this email already exists.")

        password_hash = hash_password(request.password)
        insert_query = """
        INSERT INTO users (full_name, email, password_hash)
        VALUES (%s, %s, %s)
        """

        async with self._database.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    insert_query,
                    (request.full_name.strip(), request.email.lower(), password_hash),
                )
                user_id = cursor.lastrowid

        user = UserResponse(
            id=int(user_id),
            full_name=request.full_name.strip(),
            email=request.email.lower(),
        )
        return self._build_auth_response(user)

    async def login(self, request: LoginRequest) -> AuthResponse:
        user_row = await self._get_user_by_email(request.email)
        if user_row is None:
            raise AuthServiceError("Invalid email or password.")

        if not verify_password(request.password, user_row["password_hash"]):
            raise AuthServiceError("Invalid email or password.")

        user = UserResponse(
            id=int(user_row["id"]),
            full_name=user_row["full_name"],
            email=user_row["email"],
        )
        return self._build_auth_response(user)

    async def get_user_by_id(self, user_id: int) -> UserResponse | None:
        select_query = """
        SELECT id, full_name, email
        FROM users
        WHERE id = %s
        LIMIT 1
        """

        async with self._database.pool.acquire() as connection:
            async with connection.cursor(DictCursor) as cursor:
                await cursor.execute(select_query, (user_id,))
                user_row = await cursor.fetchone()

        if user_row is None:
            return None

        return UserResponse(
            id=int(user_row["id"]),
            full_name=user_row["full_name"],
            email=user_row["email"],
        )

    async def _get_user_by_email(self, email: str) -> dict | None:
        select_query = """
        SELECT id, full_name, email, password_hash
        FROM users
        WHERE email = %s
        LIMIT 1
        """

        async with self._database.pool.acquire() as connection:
            async with connection.cursor(DictCursor) as cursor:
                await cursor.execute(select_query, (email.lower(),))
                return await cursor.fetchone()

    def _build_auth_response(self, user: UserResponse) -> AuthResponse:
        access_token = create_access_token(
            subject=str(user.id),
            settings=self._settings,
            expires_delta=timedelta(
                minutes=self._settings.jwt_access_token_expire_minutes,
            ),
        )

        return AuthResponse(
            access_token=access_token,
            token_type="bearer",
            user=user,
        )
