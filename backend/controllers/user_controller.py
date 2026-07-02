from database import get_connection
import bcrypt


# ================= REGISTER =================
def register_user(data):
    conn = get_connection()
    if not conn:
        return False

    try:
        cursor = conn.cursor()

        hashed_password = bcrypt.hashpw(
            data["password"].encode("utf-8"),
            bcrypt.gensalt()
        ).decode("utf-8")

        cursor.execute("""
            INSERT INTO usuarios(nombre,email,telefono,password,rol)
            VALUES(%s,%s,%s,%s,%s)
        """, (
            data["nombre"],
            data["email"],
            data["telefono"],
            hashed_password,
            "usuario"
        ))

        conn.commit()
        cursor.close()
        conn.close()
        return True

    except Exception as e:
        print("REGISTER ERROR:", e)
        return False


# ================= LOGIN =================
def login_user(email, password):
    conn = get_connection()
    if not conn:
        return None

    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, nombre, email, telefono, password, rol
        FROM usuarios
        WHERE email=%s
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

    return {
        "id": user[0],
        "nombre": user[1],
        "email": user[2],
        "telefono": user[3],
        "rol": user[5]
    }


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

        cursor.close()
        conn.close()

        if not user:
            return False

        return True

    except Exception as e:
        print("FORGOT PASSWORD ERROR:", e)
        return False


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
            SET password=%s
            WHERE email=%s
        """, (
            hashed_password,
            email
        ))

        conn.commit()

        updated = cursor.rowcount

        cursor.close()
        conn.close()

        return updated > 0

    except Exception as e:
        print("RESET PASSWORD ERROR:", e)
        return False