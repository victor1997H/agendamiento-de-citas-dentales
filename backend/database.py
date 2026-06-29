import psycopg2

def get_connection():
    try:
        connection = psycopg2.connect(
            host="localhost",
            port="5432",
            database="dentis_db",
            user="postgres",
            password="12345"
        )
        return connection

    except Exception as e:
        print("ERROR CONEXIÓN POSTGRES:", e)
        return None