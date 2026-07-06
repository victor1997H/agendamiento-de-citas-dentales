import os

import psycopg2

def get_connection():
    try:
        database_url = os.getenv("DATABASE_URL")

        if database_url:
            return psycopg2.connect(database_url)

        connection = psycopg2.connect(
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "5432"),
            database=os.getenv("DB_NAME", "dentis_db"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "12345")
        )
        return connection
    except Exception as e:
        print("ERROR CONEXIÓN POSTGRES:", e)
        return None
