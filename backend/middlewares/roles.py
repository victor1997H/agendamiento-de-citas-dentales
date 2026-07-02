from functools import wraps
from flask import request, jsonify

def role_required(role):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not hasattr(request, "user"):
                return jsonify({"message": "No autenticado"}), 401

            if request.user["rol"] != role:
                return jsonify({"message": "No autorizado"}), 403

            return func(*args, **kwargs)
        return wrapper
    return decorator