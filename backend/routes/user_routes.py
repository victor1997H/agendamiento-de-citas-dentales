from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta, timezone
import jwt
import re

from config.jwt_config import SECRET_KEY, ALGORITHM
from controllers.user_controller import (
    login_user,
    register_user,
    forgot_password_user,
    reset_password_user,
    update_profile_user,
)
from middlewares.jwt_auth import token_required

user_bp = Blueprint("user_bp", __name__)

EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
PHONE_RE = re.compile(r"^\+?[0-9]{7,15}$")


def validate_password(password):
    if not password or len(password) < 8:
        return "La contraseña debe tener mínimo 8 caracteres"
    if not re.search(r"[A-Z]", password):
        return "La contraseña debe incluir una mayúscula"
    if not re.search(r"[a-z]", password):
        return "La contraseña debe incluir una minúscula"
    if not re.search(r"[0-9]", password):
        return "La contraseña debe incluir un número"
    return None


def normalize_register_data(data):
    nombre = (data.get("nombre") or "").strip()
    email = (data.get("email") or "").strip().lower()
    telefono = re.sub(r"[\s()-]", "", (data.get("telefono") or "").strip())
    password = data.get("password") or ""

    if not nombre:
        return None, "Nombre requerido"
    if not EMAIL_RE.match(email):
        return None, "Correo inválido"
    if not PHONE_RE.match(telefono):
        return None, "Teléfono inválido"

    password_error = validate_password(password)
    if password_error:
        return None, password_error

    return {
        "nombre": nombre,
        "email": email,
        "telefono": telefono,
        "password": password,
    }, None


def create_token(user):
    payload = {
        "id": user["id"],
        "nombre": user["nombre"],
        "email": user["email"],
        "telefono": user["telefono"],
        "rol": user["rol"],
        "especialidad": user.get("especialidad"),
        "perfil_completo": user.get("perfil_completo", True),
        "exp": datetime.now(timezone.utc) + timedelta(hours=8),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


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

        data, error = normalize_register_data(data)

        if error:
            return jsonify({
                "success": False,
                "message": error
            }), 400

        ok = register_user(data)

        return jsonify({
            "success": ok,
            "message": "Usuario registrado" if ok else "No se pudo registrar el usuario"
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

        email = (data.get("email") or "").strip().lower()
        password = data.get("password") or ""

        if not EMAIL_RE.match(email) or not password:
            return jsonify({
                "success": False,
                "message": "Credenciales inválidas"
            }), 400

        user = login_user(email, password)

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


# ================= UPDATE PROFILE =================
@user_bp.route("/me", methods=["PUT"])
@token_required
def update_profile():
    try:
        data = request.get_json() or {}

        nombre = (data.get("nombre") or "").strip()
        email = (data.get("email") or "").strip().lower()
        telefono = re.sub(r"[\s()-]", "", (data.get("telefono") or "").strip())
        especialidad = (data.get("especialidad") or "Odontólogo General").strip()
        password = data.get("password") or ""

        if not nombre:
            return jsonify({"success": False, "message": "Nombre requerido"}), 400
        if not EMAIL_RE.match(email):
            return jsonify({"success": False, "message": "Correo inválido"}), 400
        if not PHONE_RE.match(telefono):
            return jsonify({"success": False, "message": "Teléfono inválido"}), 400

        if password:
            password_error = validate_password(password)
            if password_error:
                return jsonify({"success": False, "message": password_error}), 400

        user = update_profile_user(request.user["id"], {
            "nombre": nombre,
            "email": email,
            "telefono": telefono,
            "especialidad": especialidad,
            "password": password,
        })

        if not user:
            return jsonify({
                "success": False,
                "message": "No se pudo actualizar el perfil"
            }), 400

        return jsonify({
            "success": True,
            "usuario": user,
            "token": create_token(user)
        }), 200

    except Exception as e:
        print("UPDATE PROFILE ROUTE ERROR:", e)
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

        email = (data.get("email") or "").strip().lower()

        if not EMAIL_RE.match(email):
            return jsonify({
                "success": False,
                "message": "Correo inválido"
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

        email = (data.get("email") or "").strip().lower()
        new_password = data.get("new_password")

        if not EMAIL_RE.match(email) or not new_password:
            return jsonify({
                "success": False,
                "message": "Email y nueva contraseña son requeridos"
            }), 400

        password_error = validate_password(new_password)
        if password_error:
            return jsonify({
                "success": False,
                "message": password_error
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
