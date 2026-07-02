from database import get_connection


def get_citas():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT id, paciente, fecha, estado FROM citas")
    rows = cur.fetchall()

    conn.close()

    return [
        {"id": r[0], "paciente": r[1], "fecha": r[2], "estado": r[3]}
        for r in rows
    ]


def add_cita(data):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        INSERT INTO citas (paciente, fecha, estado)
        VALUES (%s, %s, %s)
        RETURNING id
    """, (data["paciente"], data["fecha"], "pendiente"))

    new_id = cur.fetchone()[0]
    conn.commit()
    conn.close()

    return {
        "id": new_id,
        "paciente": data["paciente"],
        "fecha": data["fecha"],
        "estado": "pendiente"
    }


def update_estado(id, estado):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        UPDATE citas SET estado=%s WHERE id=%s
        RETURNING id, paciente, fecha, estado
    """, (estado, id))

    row = cur.fetchone()
    conn.commit()
    conn.close()

    return {
        "id": row[0],
        "paciente": row[1],
        "fecha": row[2],
        "estado": row[3]
    }