from database import get_connection
import bcrypt
import jwt
import datetime
from cryptography.fernet import Fernet
from config.settings import KEY_FERNET
from config.jwt_config import SECRET_KEY, ALGORITHM

fernet = Fernet(KEY_FERNET)


# ================= REGISTER =================
def register_user(data):
    nombre = data["nombre"]
    email = data["email"]
    telefono = data["telefono"]
    password = data["password"]
    rol = data.get("rol", "usuario")

    password_hash = bcrypt.hashpw(
        password.encode("utf-8"),
        bcrypt.gensalt()
    ).decode("utf-8")

    telefono_encriptado = fernet.encrypt(
        telefono.encode("utf-8")
    ).decode("utf-8")

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO usuarios (nombre, email, telefono, password, rol)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id
    """, (nombre, email, telefono_encriptado, password_hash, rol))

    user_id = cursor.fetchone()[0]

    conn.commit()
    cursor.close()
    conn.close()

    return user_id


# ================= LOGIN =================
def login_user(data):
    email = data["email"]
    password = data["password"]

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, nombre, email, password, rol
        FROM usuarios
        WHERE email = %s
    """, (email,))

    user = cursor.fetchone()

    cursor.close()
    conn.close()

    if user and bcrypt.checkpw(
        password.encode("utf-8"),
        user[3].encode("utf-8")
    ):
        return {
            "id": user[0],
            "nombre": user[1],
            "email": user[2],
            "rol": user[4]
        }

    return None


# ================= GENERAR TOKEN JWT =================
def generate_token(user):
    payload = {
        "id": user["id"],
        "nombre": user["nombre"],
        "email": user["email"],
        "rol": user["rol"],
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=2)
    }

    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

    return token


# ================= GET USERS =================
def get_users():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, nombre, email, telefono, rol
        FROM usuarios
        ORDER BY id DESC
    """)

    rows = cursor.fetchall()
    usuarios = []

    for row in rows:
        telefono = fernet.decrypt(row[3].encode()).decode()

        usuarios.append({
            "id": row[0],
            "nombre": row[1],
            "email": row[2],
            "telefono": telefono,
            "rol": row[4]
        })

    cursor.close()
    conn.close()

    return usuarios