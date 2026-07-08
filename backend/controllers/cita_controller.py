from datetime import datetime, time, timedelta

from database import get_connection

ALLOWED_STATES = {"pendiente", "confirmada", "completada", "cancelada", "no_asistio"}


class ValidationError(Exception):
    pass


class ScheduleConflictError(Exception):
    pass


def get_citas(user):
    conn = get_connection()
    cur = conn.cursor()

    query = """
        SELECT c.id, c.usuario_id, c.paciente, c.fecha, c.estado, c.servicio,
               c.notas, c.doctor_id, COALESCE(o.nombre, 'Dr. Roberto Méndez') AS doctor,
               COALESCE(s.duracion_minutos, 45) AS duracion
        FROM citas c
        LEFT JOIN odontologos o ON o.id = c.doctor_id
        LEFT JOIN servicios s ON s.id = c.servicio_id
    """
    params = []

    if user["rol"] == "usuario":
        query += " WHERE c.usuario_id = %s"
        params.append(user["id"])
    elif user["rol"] == "doctor":
        cur.execute("SELECT id FROM odontologos WHERE usuario_id = %s", (user["id"],))
        doctor = cur.fetchone()
        if doctor:
            query += " WHERE c.doctor_id = %s"
            params.append(doctor[0])

    query += " ORDER BY c.fecha ASC"

    cur.execute(query, params)
    rows = cur.fetchall()

    cur.close()
    conn.close()

    return [_format_cita(row) for row in rows]


def add_cita(data, usuario_id):
    paciente = (data.get("paciente") or "").strip()
    servicio = (data.get("servicio") or "Consulta Dental").strip()
    notas = (data.get("notas") or "").strip() or None
    fecha = _parse_fecha(data.get("fecha"))

    if not paciente:
      raise ValidationError("Paciente requerido")

    if fecha <= datetime.now():
        raise ValidationError("La cita debe ser futura")

    conn = get_connection()
    cur = conn.cursor()

    try:
        doctor_id = _resolve_doctor_id(cur, data.get("doctor_id"))
        servicio_id = _resolve_service_id(cur, servicio)

        if doctor_id:
            if not _is_datetime_available(cur, doctor_id, fecha):
                raise ValidationError("Horario fuera de disponibilidad")

            cur.execute("""
                SELECT id
                FROM citas
                WHERE doctor_id = %s
                  AND fecha = %s
                  AND estado NOT IN ('cancelada', 'no_asistio')
                LIMIT 1
            """, (doctor_id, fecha))

            if cur.fetchone():
                raise ScheduleConflictError("Horario no disponible")

        cur.execute("""
            INSERT INTO citas (
                usuario_id, doctor_id, servicio_id, paciente,
                servicio, fecha, estado, notas
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            usuario_id,
            doctor_id,
            servicio_id,
            paciente,
            servicio,
            fecha,
            "pendiente",
            notas,
        ))

        new_id = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO notificaciones(usuario_id, cita_id, titulo, mensaje)
            VALUES (%s, %s, %s, %s)
        """, (
            usuario_id,
            new_id,
            "Cita registrada",
            f"Tu cita de {servicio} quedó pendiente de confirmación.",
        ))

        conn.commit()

        return get_cita_by_id(new_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def update_estado(id, estado):
    estado = (estado or "").strip().lower()
    if estado not in ALLOWED_STATES:
        raise ValidationError("Estado inválido")

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        UPDATE citas
        SET estado = %s, updated_at = NOW()
        WHERE id = %s
        RETURNING id
    """, (estado, id))

    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if not row:
        return None

    return get_cita_by_id(row[0])


def cancel_cita_usuario(id, usuario_id):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        UPDATE citas
        SET estado = 'cancelada', updated_at = NOW()
        WHERE id = %s AND usuario_id = %s
        RETURNING id
    """, (id, usuario_id))

    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if not row:
        return None

    return get_cita_by_id(row[0])


def get_cita_by_id(id):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT c.id, c.usuario_id, c.paciente, c.fecha, c.estado, c.servicio,
               c.notas, c.doctor_id, COALESCE(o.nombre, 'Dr. Roberto Méndez') AS doctor,
               COALESCE(s.duracion_minutos, 45) AS duracion
        FROM citas c
        LEFT JOIN odontologos o ON o.id = c.doctor_id
        LEFT JOIN servicios s ON s.id = c.servicio_id
        WHERE c.id = %s
    """, (id,))

    row = cur.fetchone()
    cur.close()
    conn.close()

    return _format_cita(row) if row else None


def get_citas_hoy(user):
    conn = get_connection()
    cur = conn.cursor()

    query = """
        SELECT c.id, c.usuario_id, c.paciente, c.fecha, c.estado, c.servicio,
               c.notas, c.doctor_id, COALESCE(o.nombre, 'Dr. Roberto Méndez') AS doctor,
               COALESCE(s.duracion_minutos, 45) AS duracion
        FROM citas c
        LEFT JOIN odontologos o ON o.id = c.doctor_id
        LEFT JOIN servicios s ON s.id = c.servicio_id
        WHERE c.fecha::date = CURRENT_DATE
    """
    params = []

    if user["rol"] == "doctor":
        cur.execute("SELECT id FROM odontologos WHERE usuario_id = %s", (user["id"],))
        doctor = cur.fetchone()
        if doctor:
            query += " AND c.doctor_id = %s"
            params.append(doctor[0])

    query += " ORDER BY c.fecha ASC"

    cur.execute(query, params)
    rows = cur.fetchall()

    cur.close()
    conn.close()

    return [_format_cita(row) for row in rows]


def get_resumen_doctor(user):
    conn = get_connection()
    cur = conn.cursor()
    params = []
    where_clause = ""

    if user["rol"] == "doctor":
        cur.execute("SELECT id FROM odontologos WHERE usuario_id = %s", (user["id"],))
        doctor = cur.fetchone()
        if doctor:
            where_clause = "WHERE c.doctor_id = %s"
            params.append(doctor[0])

    cur.execute(f"""
        SELECT
            COUNT(*) FILTER (WHERE c.fecha::date = CURRENT_DATE) AS citas_hoy,
            COUNT(*) FILTER (WHERE c.estado = 'completada') AS completadas,
            COUNT(*) FILTER (WHERE c.estado = 'pendiente') AS pendientes,
            COUNT(*) FILTER (
                WHERE EXTRACT(MONTH FROM c.fecha::date) = EXTRACT(MONTH FROM CURRENT_DATE)
                AND EXTRACT(YEAR FROM c.fecha::date) = EXTRACT(YEAR FROM CURRENT_DATE)
            ) AS este_mes
        FROM citas c
        {where_clause}
    """, params)

    row = cur.fetchone()
    cur.close()
    conn.close()

    return {
        "citas_hoy": row[0] or 0,
        "completadas": row[1] or 0,
        "pendientes": row[2] or 0,
        "este_mes": row[3] or 0,
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


def get_disponibilidad(user=None, doctor_id=None):
    conn = get_connection()
    cur = conn.cursor()

    params = []
    where_clause = "WHERE o.activo = TRUE"

    if user and user.get("rol") == "doctor":
        doctor_id = _resolve_doctor_id(cur, None, user_id=user["id"])

    if doctor_id:
        where_clause += " AND d.doctor_id = %s"
        params.append(doctor_id)

    cur.execute(f"""
        SELECT d.id, d.doctor_id, d.fecha, d.dia_semana, d.hora_inicio, d.hora_fin, d.activo
        FROM disponibilidad_odontologos d
        JOIN odontologos o ON o.id = d.doctor_id
        {where_clause}
        ORDER BY d.fecha NULLS LAST, d.dia_semana ASC, d.hora_inicio ASC
    """, params)

    rows = cur.fetchall()
    cur.close()
    conn.close()

    return [_format_disponibilidad(row) for row in rows]


def replace_disponibilidad(data, user=None):
    bloques = data.get("bloques") or []

    conn = get_connection()
    cur = conn.cursor()

    try:
        doctor_id = _resolve_doctor_id(
            cur,
            data.get("doctor_id"),
            user_id=user["id"] if user else None,
        )
        if not doctor_id:
            raise ValidationError("Doctor no encontrado")

        cur.execute(
            "DELETE FROM disponibilidad_odontologos WHERE doctor_id = %s",
            (doctor_id,),
        )

        scopes = {}

        for bloque in bloques:
            fecha = _parse_optional_date(bloque.get("fecha"))
            dia_value = bloque.get("dia_semana")
            dia = fecha.weekday() + 1 if fecha else int(dia_value)
            inicio = _parse_time(bloque.get("hora_inicio"))
            fin = _parse_time(bloque.get("hora_fin"))
            activo = bool(bloque.get("activo", True))

            if dia < 1 or dia > 7:
                raise ValidationError("Día inválido")
            if fin <= inicio:
                raise ValidationError("La hora fin debe ser mayor a la hora inicio")

            scope = fecha.isoformat() if fecha else f"semanal:{dia}"
            for existing_inicio, existing_fin in scopes.setdefault(scope, []):
                if max(inicio, existing_inicio) < min(fin, existing_fin):
                    raise ValidationError("Los bloques de horario no deben cruzarse")
            scopes[scope].append((inicio, fin))

            cur.execute("""
                INSERT INTO disponibilidad_odontologos(
                    doctor_id, fecha, dia_semana, hora_inicio, hora_fin, activo
                )
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (doctor_id, fecha, dia, inicio, fin, activo))

        conn.commit()
        return get_disponibilidad(user=user, doctor_id=doctor_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def get_horas_disponibles(fecha_text, doctor_id=None, intervalo=30):
    fecha = _parse_date(fecha_text)

    conn = get_connection()
    cur = conn.cursor()

    try:
        resolved_doctor_id = _resolve_doctor_id(cur, doctor_id)
        if not resolved_doctor_id:
            raise ValidationError("Doctor no encontrado")

        bloques = _get_availability_blocks(cur, resolved_doctor_id, fecha)

        cur.execute("""
            SELECT fecha
            FROM citas
            WHERE doctor_id = %s
              AND fecha::date = %s
              AND estado NOT IN ('cancelada', 'no_asistio')
        """, (resolved_doctor_id, fecha.date()))
        ocupadas = {
            row[0].strftime("%H:%M") if hasattr(row[0], "strftime") else str(row[0])[:5]
            for row in cur.fetchall()
        }

        now = datetime.now()
        horas = []

        for inicio, fin in bloques:
            actual = datetime.combine(fecha.date(), inicio)
            limite = datetime.combine(fecha.date(), fin)

            while actual < limite:
                hora = actual.strftime("%H:%M")
                if hora not in ocupadas and actual > now:
                    horas.append(hora)
                actual += timedelta(minutes=intervalo)

        return {
            "doctor_id": resolved_doctor_id,
            "fecha": fecha.date().isoformat(),
            "horas": sorted(set(horas)),
        }
    finally:
        cur.close()
        conn.close()


def _get_availability_blocks(cur, doctor_id, fecha):
    dia_semana = fecha.weekday() + 1

    cur.execute("""
        SELECT hora_inicio, hora_fin
        FROM disponibilidad_odontologos
        WHERE doctor_id = %s AND fecha = %s AND activo = TRUE
        ORDER BY hora_inicio ASC
    """, (doctor_id, fecha.date()))
    bloques = cur.fetchall()

    if bloques:
        return bloques

    cur.execute("""
            SELECT hora_inicio, hora_fin
            FROM disponibilidad_odontologos
            WHERE doctor_id = %s
              AND fecha IS NULL
              AND dia_semana = %s
              AND activo = TRUE
            ORDER BY hora_inicio ASC
    """, (doctor_id, dia_semana))
    return cur.fetchall()


def _is_datetime_available(cur, doctor_id, fecha):
    hora = fecha.time()
    return any(inicio <= hora < fin for inicio, fin in _get_availability_blocks(cur, doctor_id, fecha))


def delete_cita(id):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("DELETE FROM citas WHERE id=%s RETURNING id", (id,))
    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    return row is not None


def _format_cita(row):
    fecha = row[3]
    fecha_text = fecha.isoformat() if hasattr(fecha, "isoformat") else fecha
    hora_text = fecha.strftime("%H:%M") if hasattr(fecha, "strftime") else ""

    return {
        "id": row[0],
        "usuario_id": row[1],
        "paciente": row[2],
        "fecha": fecha_text,
        "hora": hora_text,
        "estado": row[4],
        "servicio": row[5],
        "notas": row[6] or "",
        "doctor_id": row[7],
        "doctor": row[8],
        "duracion": row[9],
    }


def _format_disponibilidad(row):
    return {
        "id": row[0],
        "doctor_id": row[1],
        "fecha": row[2].isoformat() if row[2] else None,
        "dia_semana": row[3],
        "hora_inicio": row[4].strftime("%H:%M") if hasattr(row[4], "strftime") else str(row[4])[:5],
        "hora_fin": row[5].strftime("%H:%M") if hasattr(row[5], "strftime") else str(row[5])[:5],
        "activo": row[6],
    }


def _parse_fecha(value):
    if not value:
        raise ValidationError("Fecha requerida")

    try:
        if isinstance(value, str):
            normalized = value.replace("Z", "+00:00")
            parsed = datetime.fromisoformat(normalized)
            return parsed.replace(tzinfo=None)

        if isinstance(value, datetime):
            return value.replace(tzinfo=None)
    except ValueError as exc:
        raise ValidationError("Fecha inválida") from exc

    raise ValidationError("Fecha inválida")


def _parse_date(value):
    if not value:
        raise ValidationError("Fecha requerida")

    try:
        parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return parsed.replace(tzinfo=None)
    except ValueError as exc:
        try:
            return datetime.strptime(str(value), "%Y-%m-%d")
        except ValueError:
            raise ValidationError("Fecha inválida") from exc


def _parse_optional_date(value):
    if not value:
        return None

    return _parse_date(value).date()


def _parse_time(value):
    if not value:
        raise ValidationError("Hora requerida")

    try:
        parts = str(value).split(":")
        return time(hour=int(parts[0]), minute=int(parts[1]))
    except (ValueError, IndexError) as exc:
        raise ValidationError("Hora inválida") from exc


def _resolve_doctor_id(cur, requested_id, user_id=None):
    if user_id:
        cur.execute("""
            SELECT id FROM odontologos
            WHERE usuario_id = %s AND activo = TRUE
            LIMIT 1
        """, (user_id,))
        row = cur.fetchone()
        if row:
            return row[0]

    if requested_id:
        cur.execute("""
            SELECT id FROM odontologos
            WHERE id = %s AND activo = TRUE
        """, (requested_id,))
        row = cur.fetchone()
        if row:
            return row[0]

    cur.execute("""
        SELECT id FROM odontologos
        WHERE activo = TRUE
        ORDER BY id
        LIMIT 1
    """)
    row = cur.fetchone()
    return row[0] if row else None


def _resolve_service_id(cur, servicio):
    cur.execute("""
        SELECT id FROM servicios
        WHERE LOWER(nombre) = LOWER(%s)
        LIMIT 1
    """, (servicio,))
    row = cur.fetchone()

    if row:
        return row[0]

    cur.execute("""
        INSERT INTO servicios(nombre)
        VALUES (%s)
        ON CONFLICT (nombre) DO UPDATE SET nombre = EXCLUDED.nombre
        RETURNING id
    """, (servicio,))
    return cur.fetchone()[0]
