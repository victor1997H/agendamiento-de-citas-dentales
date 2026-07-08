# Como correr backend, PostgreSQL y generar APK

## 1. PostgreSQL

Crea la base:

```powershell
createdb -U postgres dentis_db
```

Crea las tablas:

```powershell
psql -U postgres -d dentis_db -f backend/schema.sql
```

Si la base ya existía antes de estos cambios, puedes aplicar solo la migración:

```powershell
psql -U postgres -d dentis_db -f backend/migrations/001_expand_smarttooth_schema.sql
psql -U postgres -d dentis_db -f backend/migrations/002_schedule_availability_and_no_show.sql
psql -U postgres -d dentis_db -f backend/migrations/003_password_reset_codes.sql
```

Si tu clave o usuario de PostgreSQL no son los del proyecto, define variables antes de iniciar Flask:

```powershell
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_NAME="dentis_db"
$env:DB_USER="postgres"
$env:DB_PASSWORD="12345"
```

Para que SmartTooth envíe correos reales al registrarse y al recuperar contraseña, define también SMTP:

```powershell
$env:SMTP_HOST="smtp.gmail.com"
$env:SMTP_PORT="587"
$env:SMTP_USER="tu_correo@gmail.com"
$env:SMTP_PASSWORD="tu_password_de_aplicacion"
$env:SMTP_FROM="SmartTooth <tu_correo@gmail.com>"
$env:SMTP_USE_TLS="true"
```

Con esto:

- Al registrar una cuenta, el backend envía un correo de bienvenida.
- Al recuperar contraseña, el backend envía un código de 6 dígitos al correo registrado.
- El cambio de contraseña solo funciona después de verificar ese código.

En desarrollo, si todavía no tienes SMTP y solo quieres probar recuperación de contraseña, puedes imprimir el código en consola:

```powershell
$env:SMTP_DEBUG_CODE="true"
```

## 2. Backend Flask

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python app.py
```

Debe quedar escuchando en:

```text
http://localhost:5000
```

Para probarlo:

```powershell
Invoke-RestMethod http://localhost:5000/
```

## 2.1 Deploy en Render

Configura el servicio web con estos valores:

```text
Root Directory: backend
Build Command: pip install -r requirements.txt
Start Command: gunicorn app:app
```

El archivo `backend/requirements.txt` incluye `gunicorn`, que Render necesita para ejecutar ese comando.

En Render > Environment agrega estas variables:

```text
SECRET_KEY=<una clave larga y privada>
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=<tu correo SMTP>
SMTP_PASSWORD=<password de aplicación o clave SMTP>
SMTP_FROM=SmartTooth <tu correo SMTP>
SMTP_USE_TLS=true
```

No subas `SMTP_PASSWORD` ni `SECRET_KEY` al repositorio. Deben vivir solo como variables de entorno.

## 3. App Flutter

La app apunta por defecto a:

```text
https://smarttooth-api.onrender.com
```

Para usar otro backend, compila con:

```powershell
flutter run --dart-define=API_BASE_URL=https://tu-api.com
```

O cambia `baseUrl` en:

- `dentis_app/lib/data/datasources/api_client.dart`
- `dentis_app/lib/core/constants/api_constants.dart`

Luego:

```powershell
cd dentis_app
flutter pub get
flutter build apk
```

La APK queda normalmente en:

```text
dentis_app/build/app/outputs/flutter-apk/app-release.apk
```
