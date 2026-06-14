from django.contrib.auth import get_user_model
from django.core.signing import BadSignature, SignatureExpired, TimestampSigner


def get_user_from_token(token):
    if not token:
        return None

    signer = TimestampSigner()
    User = get_user_model()
    try:
        username = signer.unsign(token, max_age=30 * 24 * 3600)
        return User.objects.get(username=username)
    except (SignatureExpired, BadSignature, User.DoesNotExist):
        return None
