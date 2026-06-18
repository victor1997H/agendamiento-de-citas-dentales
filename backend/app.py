from flask import Flask, request, jsonify
from flask_cors import CORS

from database import get_connection

app = Flask(__name__)
CORS(app)


@app.route("/")
def home():
    return jsonify({
        "success": True,
        "message": "API Dentis funcionando"
    })


# ==========================
# REGISTRAR USUARIO
# ==========================
@app.route("/usuarios", methods=["POST"])
def registrar_usuario():

    try:

        data = request.get_json()

        nombre = data["nombre"]
        email = data["email"]
        telefono = data["telefono"]
        password = data["password"]

        conn = get_connection()

        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO usuarios
            (
                nombre,
                email,
                telefono,
                password
            )
            VALUES (%s,%s,%s,%s)
            RETURNING id
            """,
            (
                nombre,
                email,
                telefono,
                password
            )
        )

        usuario_id = cursor.fetchone()[0]

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "id": usuario_id,
            "message": "Usuario registrado"
        }), 201

    except Exception as e:

        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ==========================
# LOGIN
# ==========================
@app.route("/login", methods=["POST"])
def login():

    try:

        data = request.get_json()

        email = data["email"]
        password = data["password"]

        conn = get_connection()

        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT
                id,
                nombre,
                email
            FROM usuarios
            WHERE email=%s
            AND password=%s
            """,
            (
                email,
                password
            )
        )

        usuario = cursor.fetchone()

        cursor.close()
        conn.close()

        if usuario:

            return jsonify({
                "success": True,
                "usuario": {
                    "id": usuario[0],
                    "nombre": usuario[1],
                    "email": usuario[2]
                }
            })

        return jsonify({
            "success": False,
            "message": "Credenciales incorrectas"
        }), 401

    except Exception as e:

        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ==========================
# LISTAR USUARIOS
# ==========================
@app.route("/usuarios", methods=["GET"])
def obtener_usuarios():

    try:

        conn = get_connection()

        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT
                id,
                nombre,
                email,
                telefono
            FROM usuarios
            ORDER BY id DESC
            """
        )

        rows = cursor.fetchall()

        usuarios = []

        for row in rows:

            usuarios.append({
                "id": row[0],
                "nombre": row[1],
                "email": row[2],
                "telefono": row[3]
            })

        cursor.close()
        conn.close()

        return jsonify(usuarios)

    except Exception as e:

        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )