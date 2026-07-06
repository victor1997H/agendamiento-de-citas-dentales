from datetime import datetime, timedelta, timezone

import jwt
from flask import Blueprint, request, jsonify

from config.jwt_config import SECRET_KEY, ALGORITHM
from controllers.user_controller import (
    login_user,
    register_user,
    forgot_password_user,
    reset_password_user,
)

user_bp = Blueprint("user_bp", __name__)


def create_token(user):
    payload = {
        "id": user["id"],
        "nombre": user["nombre"],
        "email": user["email"],
        "rol": user["rol"],
        "exp": datetime.now(timezone.utc) + timedelta(days=7),
    }

    token = jwt.encode(
        payload,
        SECRET_KEY,
        algorithm=ALGORITHM,
    )

    return token


# ================= REGISTER =================
@user_bp.route("/usuarios", methods=["POST"])
def register():
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "message": "No data"
            }), 400

        ok = register_user(data)

        return jsonify({
            "success": ok
        }), 201 if ok else 400

    except Exception as e:
        print("REGISTER ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ================= LOGIN =================
@user_bp.route("/login", methods=["POST"])
def login():
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "message": "No data"
            }), 400

        user = login_user(
            data.get("email"),
            data.get("password")
        )

        if user:
            return jsonify({
                "success": True,
                "usuario": user,
                "token": create_token(user)
            }), 200

        return jsonify({
            "success": False,
            "message": "Credenciales incorrectas"
        }), 401

    except Exception as e:
        print("LOGIN ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ================= FORGOT PASSWORD =================
@user_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "message": "No data"
            }), 400

        email = data.get("email")

        if not email:
            return jsonify({
                "success": False,
                "message": "Email requerido"
            }), 400

        ok = forgot_password_user(email)

        if ok:
            return jsonify({
                "success": True,
                "message": "Correo encontrado"
            }), 200

        return jsonify({
            "success": False,
            "message": "Correo no encontrado"
        }), 404

    except Exception as e:
        print("FORGOT PASSWORD ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ================= RESET PASSWORD =================
@user_bp.route("/reset-password", methods=["POST"])
def reset_password():
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "message": "No data"
            }), 400

        email = data.get("email")
        new_password = data.get("new_password")

        if not email or not new_password:
            return jsonify({
                "success": False,
                "message": "Email y nueva contraseña son requeridos"
            }), 400

        if len(new_password) < 6:
            return jsonify({
                "success": False,
                "message": "La contraseña debe tener mínimo 6 caracteres"
            }), 400

        ok = reset_password_user(email, new_password)

        if ok:
            return jsonify({
                "success": True,
                "message": "Contraseña actualizada correctamente"
            }), 200

        return jsonify({
            "success": False,
            "message": "Correo no encontrado"
        }), 404

    except Exception as e:
        print("RESET PASSWORD ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500