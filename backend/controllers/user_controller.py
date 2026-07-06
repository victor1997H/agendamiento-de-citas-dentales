from database import get_connection
import bcrypt


DEFAULT_DOCTOR_EMAIL = "doctor@smarttooth.com"
DEFAULT_DOCTOR_PHONE = "0999999999"


# ================= REGISTER =================
def register_user(data):
    conn = get_connection()
    if not conn:
        return False

    cursor = None
    try:
        cursor = conn.cursor()

        hashed_password = bcrypt.hashpw(
            data["password"].encode("utf-8"),
            bcrypt.gensalt()
        ).decode("utf-8")

        cursor.execute("""
            INSERT INTO usuarios(nombre,email,telefono,password_hash,rol)
            VALUES(%s,%s,%s,%s,%s)
        """, (
            data["nombre"],
            data["email"].lower(),
            data["telefono"],
            hashed_password,
            "usuario"
        ))

        conn.commit()
        return True

    except Exception as e:
        print("REGISTER ERROR:", e)
        conn.rollback()
        return False
    finally:
        if cursor:
            cursor.close()
        conn.close()


# ================= LOGIN =================
def login_user(email, password):
    conn = get_connection()
    if not conn:
        return None

    cursor = conn.cursor()

    cursor.execute("""
        SELECT u.id, u.nombre, u.email, u.telefono, u.password_hash, u.rol,
               COALESCE(o.especialidad, 'Odontólogo General') AS especialidad
        FROM usuarios u
        LEFT JOIN odontologos o ON o.usuario_id = u.id
        WHERE u.email=%s
    """, (email,))

    user = cursor.fetchone()

    cursor.close()
    conn.close()

    if not user:
        return None

    if not bcrypt.checkpw(
        password.encode("utf-8"),
        user[4].encode("utf-8")
    ):
        return None

    return _format_user(user)


def update_profile_user(user_id, data):
    conn = get_connection()
    if not conn:
        return None

    cursor = conn.cursor()

    try:
        nombre = (data.get("nombre") or "").strip()
        email = (data.get("email") or "").strip().lower()
        telefono = (data.get("telefono") or "").strip()
        especialidad = (data.get("especialidad") or "Odontólogo General").strip()
        password = data.get("password") or ""

        if not nombre or not email or not telefono:
            return None

        if password:
            hashed_password = bcrypt.hashpw(
                password.encode("utf-8"),
                bcrypt.gensalt()
            ).decode("utf-8")

            cursor.execute("""
                UPDATE usuarios
                SET nombre=%s, email=%s, telefono=%s, password_hash=%s, updated_at=NOW()
                WHERE id=%s
            """, (nombre, email, telefono, hashed_password, user_id))
        else:
            cursor.execute("""
                UPDATE usuarios
                SET nombre=%s, email=%s, telefono=%s, updated_at=NOW()
                WHERE id=%s
            """, (nombre, email, telefono, user_id))

        cursor.execute("""
            SELECT rol
            FROM usuarios
            WHERE id=%s
        """, (user_id,))
        role_row = cursor.fetchone()
        rol = role_row[0] if role_row else ""

        if rol in ("admin", "doctor"):
            cursor.execute("""
                SELECT id
                FROM odontologos
                WHERE usuario_id=%s
            """, (user_id,))
            doctor = cursor.fetchone()

            if doctor:
                cursor.execute("""
                    UPDATE odontologos
                    SET nombre=%s, especialidad=%s, telefono=%s, activo=TRUE
                    WHERE id=%s
                """, (nombre, especialidad, telefono, doctor[0]))
            else:
                cursor.execute("""
                    SELECT id
                    FROM odontologos
                    WHERE usuario_id IS NULL
                    ORDER BY id
                    LIMIT 1
                """)
                unassigned = cursor.fetchone()

                if unassigned:
                    cursor.execute("""
                        UPDATE odontologos
                        SET usuario_id=%s, nombre=%s, especialidad=%s, telefono=%s, activo=TRUE
                        WHERE id=%s
                    """, (user_id, nombre, especialidad, telefono, unassigned[0]))
                else:
                    cursor.execute("""
                        INSERT INTO odontologos(usuario_id, nombre, especialidad, telefono, activo)
                        VALUES(%s, %s, %s, %s, TRUE)
                    """, (user_id, nombre, especialidad, telefono))

        conn.commit()

        cursor.execute("""
            SELECT u.id, u.nombre, u.email, u.telefono, u.password_hash, u.rol,
                   COALESCE(o.especialidad, 'Odontólogo General') AS especialidad
            FROM usuarios u
            LEFT JOIN odontologos o ON o.usuario_id = u.id
            WHERE u.id=%s
        """, (user_id,))

        row = cursor.fetchone()
        return _format_user(row) if row else None

    except Exception as e:
        print("UPDATE PROFILE ERROR:", e)
        conn.rollback()
        return None
    finally:
        cursor.close()
        conn.close()


def _format_user(user):
    perfil_completo = True
    if user[5] in ("admin", "doctor"):
        perfil_completo = not (
            user[2] == DEFAULT_DOCTOR_EMAIL
            or user[3] == DEFAULT_DOCTOR_PHONE
            or user[1] in ("Dr. Roberto Méndez", "Dr. Roberto Mendez", "Administrador")
        )

    return {
        "id": user[0],
        "nombre": user[1],
        "email": user[2],
        "telefono": user[3],
        "rol": user[5],
        "especialidad": user[6],
        "perfil_completo": perfil_completo,
    }


def get_user_by_id(user_id):
    conn = get_connection()
    if not conn:
        return None

    cursor = conn.cursor()

    cursor.execute("""
        SELECT u.id, u.nombre, u.email, u.telefono, u.password_hash, u.rol,
               COALESCE(o.especialidad, 'Odontólogo General') AS especialidad
        FROM usuarios
        u LEFT JOIN odontologos o ON o.usuario_id = u.id
        WHERE u.id=%s
    """, (user_id,))

    user = cursor.fetchone()

    cursor.close()
    conn.close()

    return _format_user(user) if user else None


# ================= FORGOT PASSWORD =================
def forgot_password_user(email):
    conn = get_connection()
    if not conn:
        return False

    try:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT id
            FROM usuarios
            WHERE email=%s
        """, (email,))

        user = cursor.fetchone()

        if not user:
            return False

        return True

    except Exception as e:
        print("FORGOT PASSWORD ERROR:", e)
        return False
    finally:
        try:
            cursor.close()
            conn.close()
        except Exception:
            pass


# ================= RESET PASSWORD =================
def reset_password_user(email, new_password):
    conn = get_connection()
    if not conn:
        return False

    try:
        cursor = conn.cursor()

        hashed_password = bcrypt.hashpw(
            new_password.encode("utf-8"),
            bcrypt.gensalt()
        ).decode("utf-8")

        cursor.execute("""
            UPDATE usuarios
            SET password_hash=%s
            WHERE email=%s
        """, (
            hashed_password,
            email
        ))

        conn.commit()

        updated = cursor.rowcount

        return updated > 0

    except Exception as e:
        print("RESET PASSWORD ERROR:", e)
        conn.rollback()
        return False
    finally:
        try:
            cursor.close()
            conn.close()
        except Exception:
            pass
