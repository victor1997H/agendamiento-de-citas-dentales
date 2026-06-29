from functools import wraps
from flask import request, jsonify


# ================= ADMIN ONLY =================
def admin_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):

        user = request.user

        if user["rol"] != "admin":
            return jsonify({
                "success": False,
                "message": "Acceso solo para ADMIN"
            }), 403

        return func(*args, **kwargs)

    return wrapper


# ================= DOCTOR ONLY =================
def doctor_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):

        user = request.user

        if user["rol"] != "doctor":
            return jsonify({
                "success": False,
                "message": "Acceso solo para DOCTOR"
            }), 403

        return func(*args, **kwargs)

    return wrapper


# ================= USER ONLY =================
def user_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):

        user = request.user

        if user["rol"] != "usuario":
            return jsonify({
                "success": False,
                "message": "Acceso solo para USUARIO"
            }), 403

        return func(*args, **kwargs)

    return wrapper