import os

SECRET_KEY = os.getenv("SECRET_KEY", "mi_clave_super_secreta_dentis")
ALGORITHM = "HS256"
