from functools import wraps
from flask import request, jsonify


def admin_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):

        rol = request.headers.get("Rol")

        if rol != "admin":
            return jsonify({
                "success": False,
                "message": "Acceso denegado. Solo administradores."
            }), 403

        return func(*args, **kwargs)

    return wrapper