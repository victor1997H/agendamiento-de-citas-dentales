from pathlib import Path

from database import get_connection


def main():
    schema_path = Path(__file__).with_name("schema.sql")
    sql = schema_path.read_text(encoding="utf-8")

    conn = get_connection()
    if not conn:
        raise RuntimeError("No se pudo conectar a PostgreSQL")

    try:
        with conn.cursor() as cursor:
            cursor.execute(sql)
        conn.commit()
        print("Base de datos inicializada correctamente")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
