from functools import wraps
from flask import request, jsonify
import jwt
from config.jwt_config import SECRET_KEY, ALGORITHM

def token_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        token = request.headers.get("Authorization")

        if not token:
            return jsonify({"message": "Token requerido"}), 401

        try:
            token = token.split(" ")[1]
            data = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            request.user = data
        except:
            return jsonify({"message": "Token inválido"}), 401

        return func(*args, **kwargs)

    return wrapper