from flask import Blueprint, request, jsonify

from controllers.cita_controller import (
    get_citas,
    add_cita,
    update_estado
)

from middlewares.jwt_auth import token_required
from middlewares.roles import role_required

# ================= BLUEPRINT =================
cita_bp = Blueprint("cita_bp", __name__)

# ================= CREAR CITA (USUARIO) =================
@cita_bp.route("/citas", methods=["POST"])
@token_required
@role_required("usuario")
def crear_cita():
    data = request.get_json()
    nueva = add_cita(data)
    return jsonify(nueva), 201


# ================= VER CITAS (DOCTOR) =================
@cita_bp.route("/citas", methods=["GET"])
@token_required
@role_required("doctor")
def listar_citas():
    citas = get_citas()
    return jsonify(citas), 200


# ================= ACTUALIZAR ESTADO (DOCTOR) =================
@cita_bp.route("/citas/<int:id>", methods=["PUT"])
@token_required
@role_required("doctor")
def actualizar(id):
    data = request.get_json()
    result = update_estado(id, data["estado"])
    return jsonify(result), 200