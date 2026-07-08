from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta, timezone
import jwt
import re

from config.jwt_config import SECRET_KEY, ALGORITHM
from controllers.user_controller import (
    create_password_reset_code,
    get_user_by_email,
    login_user,
    register_user,
    reset_password_user,
    update_profile_user,
    verify_password_reset_code,
)
from middlewares.jwt_auth import token_required
from services.email_service import send_password_reset_code, send_welcome_email

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
    if "." not in password:
        return "La contraseña debe incluir un punto"
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
        if ok:
            sent = send_welcome_email(data["email"], data["nombre"])
            if not sent:
                print(f"WELCOME EMAIL NOT SENT: {data['email']}")

        return jsonify({
            "success": ok,
            "message": "Usuario registrado" if ok else "No se pudo registrar el usuario"
        }), 201 if ok else 400

    except Exception as e:
        print("REGISTER ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Error interno del servidor"
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
            "message": "Error interno del servidor"
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
            "message": "Error interno del servidor"
        }), 500


# ================= FORGOT PASSWORD =================
@user_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    public_message = "Si el correo está registrado, enviaremos un código de recuperación."

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

        user = get_user_by_email(email)
        if not user:
            return jsonify({
                "success": True,
                "message": public_message
            }), 200

        code = create_password_reset_code(email)
        if not code:
            print(f"RESET CODE NOT CREATED: {email}")
            return jsonify({
                "success": True,
                "message": public_message
            }), 200

        sent = send_password_reset_code(email, code)
        if not sent:
            print(f"RESET EMAIL NOT SENT: {email}")
            return jsonify({
                "success": True,
                "message": public_message
            }), 200

        return jsonify({
            "success": True,
            "message": public_message
        }), 200

    except Exception as e:
        print("FORGOT PASSWORD ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Error interno del servidor"
        }), 500


@user_bp.route("/verify-reset-code", methods=["POST"])
def verify_reset_code():
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "message": "No data"
            }), 400

        email = (data.get("email") or "").strip().lower()
        code = re.sub(r"\D", "", data.get("code") or "")

        if not EMAIL_RE.match(email) or len(code) != 6:
            return jsonify({
                "success": False,
                "message": "Código inválido"
            }), 400

        reset_token = verify_password_reset_code(email, code)

        if not reset_token:
            return jsonify({
                "success": False,
                "message": "Código inválido o expirado."
            }), 401

        return jsonify({
            "success": True,
            "reset_token": reset_token,
            "message": "Código verificado correctamente."
        }), 200

    except Exception as e:
        print("VERIFY RESET CODE ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Error interno del servidor"
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
        code = re.sub(r"\D", "", data.get("code") or "")
        reset_token = data.get("reset_token") or ""

        if not EMAIL_RE.match(email) or not new_password or not (code or reset_token):
            return jsonify({
                "success": False,
                "message": "Código y nueva contraseña son requeridos"
            }), 400

        if code and len(code) != 6:
            return jsonify({
                "success": False,
                "message": "Código inválido o expirado."
            }), 400

        password_error = validate_password(new_password)
        if password_error:
            return jsonify({
                "success": False,
                "message": password_error
            }), 400

        ok = reset_password_user(
            email,
            new_password,
            reset_token=reset_token or None,
            code=code or None,
        )

        if ok:
            return jsonify({
                "success": True,
                "message": "Contraseña actualizada correctamente."
            }), 200

        return jsonify({
            "success": False,
            "message": "Código inválido o expirado."
        }), 401

    except Exception as e:
        print("RESET PASSWORD ROUTE ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Error interno del servidor"
        }), 500
