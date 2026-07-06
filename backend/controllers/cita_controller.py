from database import get_connection


def _format_value(value):
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return value


def _format_cita(row):
    return {
        "id": row[0],
        "usuario_id": row[1],
        "paciente": row[2],
        "servicio": row[3],
        "doctor": row[4],
        "fecha": _format_value(row[5]),
        "hora": _format_value(row[6]),
        "estado": row[7],
        "notas": row[8],
        "duracion": row[9],
    }


def get_citas_usuario(usuario_id):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, usuario_id, paciente, servicio, doctor, fecha, hora, estado,
               COALESCE(notas, ''), COALESCE(duracion, 45)
        FROM citas
        WHERE usuario_id = %s
        ORDER BY fecha DESC, hora DESC
    """, (usuario_id,))

    rows = cur.fetchall()
    cur.close()
    conn.close()

    return [_format_cita(row) for row in rows]


def add_cita(usuario_id, paciente, data):
    servicio = data.get("servicio")
    fecha = data.get("fecha")
    hora = data.get("hora")
    doctor = data.get("doctor") or "Dr. Roberto Mendez"
    notas = data.get("notas")
    duracion = data.get("duracion", 45)

    if not servicio or not fecha or not hora:
        raise ValueError("servicio, fecha y hora son requeridos")

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        INSERT INTO citas (usuario_id, paciente, servicio, doctor, fecha, hora, estado, notas, duracion)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id, usuario_id, paciente, servicio, doctor, fecha, hora, estado,
                  COALESCE(notas, ''), COALESCE(duracion, 45)
    """, (
        usuario_id,
        paciente,
        servicio,
        doctor,
        fecha,
        hora,
        "pendiente",
        notas,
        duracion,
    ))

    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    return _format_cita(row)


def cancelar_cita_usuario(id, usuario_id):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        UPDATE citas
        SET estado = 'cancelada'
        WHERE id = %s AND usuario_id = %s
        RETURNING id, usuario_id, paciente, servicio, doctor, fecha, hora, estado,
                  COALESCE(notas, ''), COALESCE(duracion, 45)
    """, (id, usuario_id))

    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if not row:
        return None

    return _format_cita(row)


def get_citas_doctor():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, usuario_id, paciente, servicio, doctor, fecha, hora, estado,
               COALESCE(notas, ''), COALESCE(duracion, 45)
        FROM citas
        ORDER BY fecha DESC, hora DESC
    """)

    rows = cur.fetchall()
    cur.close()
    conn.close()

    return [_format_cita(row) for row in rows]


def get_citas_hoy():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, usuario_id, paciente, servicio, doctor, fecha, hora, estado,
               COALESCE(notas, ''), COALESCE(duracion, 45)
        FROM citas
        WHERE fecha::date = CURRENT_DATE
        ORDER BY hora ASC
    """)

    rows = cur.fetchall()
    cur.close()
    conn.close()

    return [_format_cita(row) for row in rows]


def update_estado_cita(id, estado):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        UPDATE citas
        SET estado = %s
        WHERE id = %s
        RETURNING id, usuario_id, paciente, servicio, doctor, fecha, hora, estado,
                  COALESCE(notas, ''), COALESCE(duracion, 45)
    """, (estado, id))

    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if not row:
        return None

    return _format_cita(row)


def get_resumen_doctor():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            COUNT(*) FILTER (WHERE fecha::date = CURRENT_DATE) AS citas_hoy,
            COUNT(*) FILTER (WHERE estado = 'completada') AS completadas,
            COUNT(*) FILTER (WHERE estado = 'pendiente') AS pendientes,
            COUNT(*) FILTER (
                WHERE EXTRACT(MONTH FROM fecha::date) = EXTRACT(MONTH FROM CURRENT_DATE)
                AND EXTRACT(YEAR FROM fecha::date) = EXTRACT(YEAR FROM CURRENT_DATE)
            ) AS este_mes
        FROM citas
    """)

    row = cur.fetchone()
    cur.close()
    conn.close()

    return {
        "citas_hoy": row[0],
        "completadas": row[1],
        "pendientes": row[2],
        "este_mes": row[3],
    }


def get_pacientes():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, nombre, email, telefono, rol
        FROM usuarios
        WHERE rol = 'usuario'
        ORDER BY nombre ASC
    """)

    rows = cur.fetchall()
    cur.close()
    conn.close()

    return [
        {
            "id": row[0],
            "nombre": row[1],
            "email": row[2],
            "telefono": row[3],
            "rol": row[4],
        }
        for row in rows
    ]