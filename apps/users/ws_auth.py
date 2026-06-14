from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser

from .token_auth import get_user_from_token


@database_sync_to_async
def _get_user(token):
    return get_user_from_token(token) or AnonymousUser()


class TokenAuthMiddleware:
    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        scope = dict(scope)
        query = parse_qs(scope.get("query_string", b"").decode())
        token = query.get("token", [None])[0]

        if token:
            scope["user"] = await _get_user(token)

        return await self.inner(scope, receive, send)
