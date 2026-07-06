from functools import wraps
from flask import request, jsonify
import jwt

from config.jwt_config import SECRET_KEY, ALGORITHM


def token_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")

        if not auth_header.startswith("Bearer "):
            return jsonify({
                "success": False,
                "message": "Token requerido"
            }), 401

        token = auth_header.split(" ", 1)[1]

        try:
            data = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            request.user = data
        except Exception:
            return jsonify({
                "success": False,
                "message": "Token inválido"
            }), 401

        return func(*args, **kwargs)

    return wrapper