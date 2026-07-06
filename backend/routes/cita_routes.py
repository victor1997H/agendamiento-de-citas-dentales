from flask import Blueprint, request, jsonify

from controllers.cita_controller import (
    ScheduleConflictError,
    ValidationError,
    get_citas,
    add_cita,
    update_estado,
    delete_cita,
    cancel_cita_usuario,
    get_citas_hoy,
    get_resumen_doctor,
    get_pacientes
)

from middlewares.jwt_auth import token_required

# ================= BLUEPRINT =================
cita_bp = Blueprint("cita_bp", __name__)

# ================= CREAR CITA (USUARIO) =================
@cita_bp.route("/citas", methods=["POST"])
@token_required
def crear_cita():
    if request.user["rol"] not in ("usuario", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    try:
        data = request.get_json() or {}
        nueva = add_cita(data, request.user["id"])
        return jsonify(nueva), 201
    except ValidationError as e:
        return jsonify({"success": False, "message": str(e)}), 400
    except ScheduleConflictError as e:
        return jsonify({"success": False, "message": str(e)}), 409


# ================= VER CITAS =================
@cita_bp.route("/citas", methods=["GET"])
@token_required
def listar_citas():
    citas = get_citas(request.user)
    return jsonify(citas), 200


# ================= VER MIS CITAS (USUARIO) =================
@cita_bp.route("/mis-citas", methods=["GET"])
@token_required
def mis_citas():
    if request.user["rol"] not in ("usuario", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    citas = get_citas(request.user)
    return jsonify({"success": True, "citas": citas}), 200


# ================= CANCELAR CITA (USUARIO) =================
@cita_bp.route("/citas/<int:id>/cancelar", methods=["PUT"])
@token_required
def cancelar_cita(id):
    if request.user["rol"] == "usuario":
        result = cancel_cita_usuario(id, request.user["id"])
    elif request.user["rol"] == "admin":
        result = update_estado(id, "cancelada")
    else:
        return jsonify({"success": False, "message": "No autorizado"}), 403

    if not result:
        return jsonify({"success": False, "message": "Cita no encontrada"}), 404

    return jsonify({"success": True, "cita": result}), 200


# ================= TODAS LAS CITAS (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/citas", methods=["GET"])
@token_required
def doctor_citas():
    if request.user["rol"] not in ("doctor", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    citas = get_citas(request.user)
    return jsonify({"success": True, "citas": citas}), 200


# ================= CITAS DE HOY (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/citas-hoy", methods=["GET"])
@token_required
def doctor_citas_hoy():
    if request.user["rol"] not in ("doctor", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    citas = get_citas_hoy(request.user)
    return jsonify({"success": True, "citas": citas}), 200


# ================= RESUMEN DOCTOR =================
@cita_bp.route("/doctor/resumen", methods=["GET"])
@token_required
def doctor_resumen():
    if request.user["rol"] not in ("doctor", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    resumen = get_resumen_doctor(request.user)
    return jsonify({"success": True, "resumen": resumen}), 200


# ================= PACIENTES (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/pacientes", methods=["GET"])
@token_required
def doctor_pacientes():
    if request.user["rol"] not in ("doctor", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    pacientes = get_pacientes()
    return jsonify({"success": True, "pacientes": pacientes}), 200


# ================= ACTUALIZAR ESTADO (DOCTOR) =================
@cita_bp.route("/citas/<int:id>", methods=["PUT"])
@token_required
def actualizar(id):
    if request.user["rol"] not in ("doctor", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    try:
        data = request.get_json() or {}
        result = update_estado(id, data.get("estado"))
    except ValidationError as e:
        return jsonify({"success": False, "message": str(e)}), 400

    if not result:
        return jsonify({"success": False, "message": "Cita no encontrada"}), 404

    return jsonify(result), 200


# ================= ACTUALIZAR ESTADO (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/citas/<int:id>/estado", methods=["PUT"])
@token_required
def doctor_actualizar_estado(id):
    if request.user["rol"] not in ("doctor", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    try:
        data = request.get_json() or {}
        result = update_estado(id, data.get("estado"))
    except ValidationError as e:
        return jsonify({"success": False, "message": str(e)}), 400

    if not result:
        return jsonify({"success": False, "message": "Cita no encontrada"}), 404

    return jsonify({"success": True, "cita": result}), 200


# ================= ELIMINAR CITA (DOCTOR) =================
@cita_bp.route("/citas/<int:id>", methods=["DELETE"])
@token_required
def eliminar(id):
    if request.user["rol"] not in ("doctor", "admin"):
        return jsonify({"success": False, "message": "No autorizado"}), 403

    ok = delete_cita(id)

    if not ok:
        return jsonify({"success": False, "message": "Cita no encontrada"}), 404

    return jsonify({"success": True}), 200
