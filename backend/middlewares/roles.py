from functools import wraps
from flask import request, jsonify


def role_required(*roles):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            user = getattr(request, "user", None)

            if not user or user.get("rol") not in roles:
                return jsonify({
                    "success": False,
                    "message": "No tienes permiso para esta acción"
                }), 403

            return func(*args, **kwargs)

        return wrapper

    return decorator