from functools import wraps
from flask import request, jsonify
import jwt

from config.jwt_config import SECRET_KEY, ALGORITHM


def token_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):

        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return jsonify({
                "success": False,
                "message": "Token requerido"
            }), 401

        try:
            token = auth_header.split(" ")[1]  # Bearer TOKEN

            data = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

            # 🔥 AQUÍ SE GUARDA EL USUARIO EN LA REQUEST
            request.user = data

        except jwt.ExpiredSignatureError:
            return jsonify({
                "success": False,
                "message": "Token expirado"
            }), 401

        except jwt.InvalidTokenError:
            return jsonify({
                "success": False,
                "message": "Token inválido"
            }), 401

        except Exception as e:
            return jsonify({
                "success": False,
                "message": "Error de autenticación",
                "error": str(e)
            }), 401

        return func(*args, **kwargs)

    return wrapper