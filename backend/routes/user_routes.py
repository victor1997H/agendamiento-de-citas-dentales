from flask import Blueprint, request, jsonify

from controllers.user_controller import (
    register_user,
    login_user,
    get_users,
    generate_token
)

from middlewares.jwt_auth import token_required


user_bp = Blueprint("user_bp", __name__)


# ================= REGISTER =================
@user_bp.route("/usuarios", methods=["POST"])
def register():
    try:
        data = request.get_json()

        user_id = register_user(data)

        return jsonify({
            "success": True,
            "id": user_id
        }), 201

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ================= LOGIN =================
@user_bp.route("/login", methods=["POST"])
def login():
    try:
        data = request.get_json()

        user = login_user(data)

        if user:
            token = generate_token(user)

            return jsonify({
                "success": True,
                "usuario": user,
                "token": token
            }), 200

        return jsonify({
            "success": False,
            "message": "Credenciales incorrectas"
        }), 401

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ================= GET USERS (PROTEGIDO JWT) =================
@user_bp.route("/usuarios", methods=["GET"])
@token_required
def users():
    try:
        usuarios = get_users()

        return jsonify({
            "success": True,
            "data": usuarios
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500