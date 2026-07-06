from flask import Blueprint, request, jsonify

from controllers.cita_controller import (
    add_cita,
    get_citas_usuario,
    cancelar_cita_usuario,
    get_citas_doctor,
    get_citas_hoy,
    update_estado_cita,
    get_resumen_doctor,
    get_pacientes,
)

from middlewares.jwt_auth import token_required
from middlewares.roles import role_required

cita_bp = Blueprint("cita_bp", __name__)


# ================= CREAR CITA (USUARIO) =================
@cita_bp.route("/citas", methods=["POST"])
@token_required
@role_required("usuario")
def crear_cita():
    try:
        data = request.get_json() or {}

        nueva = add_cita(
            request.user["id"],
            request.user.get("nombre", "Paciente"),
            data
        )

        return jsonify({
            "success": True,
            "cita": nueva
        }), 201

    except ValueError as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 400

    except Exception as e:
        print("CREAR CITA ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudo crear la cita"
        }), 500


# ================= VER MIS CITAS (USUARIO) =================
@cita_bp.route("/mis-citas", methods=["GET"])
@token_required
@role_required("usuario")
def mis_citas():
    try:
        citas = get_citas_usuario(request.user["id"])

        return jsonify({
            "success": True,
            "citas": citas
        }), 200

    except Exception as e:
        print("MIS CITAS ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudieron cargar las citas"
        }), 500


# ================= CANCELAR CITA (USUARIO) =================
@cita_bp.route("/citas/<int:id>/cancelar", methods=["PUT"])
@token_required
@role_required("usuario")
def cancelar_cita(id):
    try:
        cita = cancelar_cita_usuario(id, request.user["id"])

        if not cita:
            return jsonify({
                "success": False,
                "message": "Cita no encontrada"
            }), 404

        return jsonify({
            "success": True,
            "cita": cita
        }), 200

    except Exception as e:
        print("CANCELAR CITA ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudo cancelar la cita"
        }), 500


# ================= TODAS LAS CITAS (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/citas", methods=["GET"])
@token_required
@role_required("doctor", "admin")
def doctor_citas():
    try:
        citas = get_citas_doctor()

        return jsonify({
            "success": True,
            "citas": citas
        }), 200

    except Exception as e:
        print("DOCTOR CITAS ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudieron cargar las citas"
        }), 500


# ================= CITAS DE HOY (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/citas-hoy", methods=["GET"])
@token_required
@role_required("doctor", "admin")
def doctor_citas_hoy():
    try:
        citas = get_citas_hoy()

        return jsonify({
            "success": True,
            "citas": citas
        }), 200

    except Exception as e:
        print("DOCTOR CITAS HOY ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudo cargar la agenda de hoy"
        }), 500


# ================= RESUMEN DOCTOR =================
@cita_bp.route("/doctor/resumen", methods=["GET"])
@token_required
@role_required("doctor", "admin")
def doctor_resumen():
    try:
        resumen = get_resumen_doctor()

        return jsonify({
            "success": True,
            "resumen": resumen
        }), 200

    except Exception as e:
        print("DOCTOR RESUMEN ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudo cargar el resumen"
        }), 500


# ================= ACTUALIZAR ESTADO CITA (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/citas/<int:id>/estado", methods=["PUT"])
@token_required
@role_required("doctor", "admin")
def doctor_actualizar_estado(id):
    try:
        data = request.get_json() or {}
        estado = data.get("estado")

        if estado not in ["pendiente", "confirmada", "completada", "cancelada"]:
            return jsonify({
                "success": False,
                "message": "Estado inválido"
            }), 400

        cita = update_estado_cita(id, estado)

        if not cita:
            return jsonify({
                "success": False,
                "message": "Cita no encontrada"
            }), 404

        return jsonify({
            "success": True,
            "cita": cita
        }), 200

    except Exception as e:
        print("DOCTOR UPDATE ESTADO ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudo actualizar la cita"
        }), 500


# ================= PACIENTES (DOCTOR / ADMIN) =================
@cita_bp.route("/doctor/pacientes", methods=["GET"])
@token_required
@role_required("doctor", "admin")
def doctor_pacientes():
    try:
        pacientes = get_pacientes()

        return jsonify({
            "success": True,
            "pacientes": pacientes
        }), 200

    except Exception as e:
        print("DOCTOR PACIENTES ERROR:", e)
        return jsonify({
            "success": False,
            "message": "No se pudieron cargar los pacientes"
        }), 500