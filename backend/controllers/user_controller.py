from database import get_connection
import bcrypt
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from hashlib import sha256

from config.jwt_config import SECRET_KEY


DEFAULT_DOCTOR_EMAIL = "doctor@smarttooth.com"
DEFAULT_DOCTOR_PHONE = "0999999999"
RESET_CODE_MINUTES = 10
RESET_TOKEN_MINUTES = 15
MAX_RESET_ATTEMPTS = 5


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


def get_user_by_email(email):
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


def create_password_reset_code(email):
    user = get_user_by_email(email)
    if not user:
        return None

    conn = get_connection()
    if not conn:
        return None

    cursor = None
    try:
        cursor = conn.cursor()
        _ensure_password_reset_table(cursor)

        code = f"{secrets.randbelow(1000000):06d}"
        code_hash = _hash_secret(code)
        expires_at = _utc_now() + timedelta(minutes=RESET_CODE_MINUTES)

        cursor.execute("""
            UPDATE password_reset_codes
            SET used_at=NOW()
            WHERE user_id=%s AND used_at IS NULL
        """, (user["id"],))

        cursor.execute("""
            INSERT INTO password_reset_codes(user_id, code_hash, expires_at)
            VALUES(%s, %s, %s)
        """, (user["id"], code_hash, expires_at))

        conn.commit()
        return code
    except Exception as e:
        print("CREATE RESET CODE ERROR:", e)
        conn.rollback()
        return None
    finally:
        if cursor:
            cursor.close()
        conn.close()


def verify_password_reset_code(email, code):
    user = get_user_by_email(email)
    if not user:
        return None

    conn = get_connection()
    if not conn:
        return None

    cursor = None
    try:
        cursor = conn.cursor()
        _ensure_password_reset_table(cursor)

        cursor.execute("""
            SELECT id, code_hash, attempts, expires_at
            FROM password_reset_codes
            WHERE user_id=%s AND used_at IS NULL AND reset_token_hash IS NULL
            ORDER BY created_at DESC
            LIMIT 1
            FOR UPDATE
        """, (user["id"],))

        row = cursor.fetchone()
        if not row:
            conn.rollback()
            return None

        reset_id, code_hash, attempts, expires_at = row
        if _is_expired(expires_at) or attempts >= MAX_RESET_ATTEMPTS:
            cursor.execute("""
                UPDATE password_reset_codes
                SET used_at=NOW()
                WHERE id=%s
            """, (reset_id,))
            conn.commit()
            return None

        if not hmac.compare_digest(code_hash, _hash_secret(code)):
            cursor.execute("""
                UPDATE password_reset_codes
                SET attempts=attempts + 1
                WHERE id=%s
            """, (reset_id,))
            conn.commit()
            return None

        reset_token = secrets.token_urlsafe(32)
        reset_token_hash = _hash_secret(reset_token)
        token_expires_at = _utc_now() + timedelta(minutes=RESET_TOKEN_MINUTES)

        cursor.execute("""
            UPDATE password_reset_codes
            SET reset_token_hash=%s, token_expires_at=%s
            WHERE id=%s
        """, (reset_token_hash, token_expires_at, reset_id))

        conn.commit()
        return reset_token
    except Exception as e:
        print("VERIFY RESET CODE ERROR:", e)
        conn.rollback()
        return None
    finally:
        if cursor:
            cursor.close()
        conn.close()


# ================= RESET PASSWORD =================
def reset_password_user(email, new_password, reset_token=None):
    conn = get_connection()
    if not conn:
        return False

    cursor = None
    try:
        cursor = conn.cursor()
        _ensure_password_reset_table(cursor)

        if not reset_token:
            return False

        cursor.execute("""
            SELECT prc.id, prc.token_expires_at
            FROM password_reset_codes prc
            INNER JOIN usuarios u ON u.id = prc.user_id
            WHERE u.email=%s
              AND prc.reset_token_hash=%s
              AND prc.used_at IS NULL
            ORDER BY prc.created_at DESC
            LIMIT 1
            FOR UPDATE
        """, (email, _hash_secret(reset_token)))

        reset_row = cursor.fetchone()
        if not reset_row:
            conn.rollback()
            return False

        reset_id, token_expires_at = reset_row
        if _is_expired(token_expires_at):
            cursor.execute("""
                UPDATE password_reset_codes
                SET used_at=NOW()
                WHERE id=%s
            """, (reset_id,))
            conn.commit()
            return False

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

        cursor.execute("""
            UPDATE password_reset_codes
            SET used_at=NOW()
            WHERE id=%s
        """, (reset_id,))

        conn.commit()

        updated = cursor.rowcount

        return updated > 0

    except Exception as e:
        print("RESET PASSWORD ERROR:", e)
        conn.rollback()
        return False
    finally:
        if cursor:
            cursor.close()
        conn.close()


def _hash_secret(value):
    return hmac.new(
        SECRET_KEY.encode("utf-8"),
        value.encode("utf-8"),
        sha256
    ).hexdigest()


def _utc_now():
    return datetime.now(timezone.utc)


def _is_expired(value):
    if value is None:
        return True

    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)

    return _utc_now() > value


def _ensure_password_reset_table(cursor):
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS password_reset_codes (
            id SERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
            code_hash TEXT NOT NULL,
            reset_token_hash TEXT,
            attempts INTEGER NOT NULL DEFAULT 0,
            expires_at TIMESTAMPTZ NOT NULL,
            token_expires_at TIMESTAMPTZ,
            used_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_password_reset_codes_user_active
        ON password_reset_codes(user_id, used_at, created_at DESC)
    """)
