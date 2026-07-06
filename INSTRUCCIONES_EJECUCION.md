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
```

Si tu clave o usuario de PostgreSQL no son los del proyecto, define variables antes de iniciar Flask:

```powershell
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_NAME="dentis_db"
$env:DB_USER="postgres"
$env:DB_PASSWORD="12345"
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

## 3. App Flutter

La app apunta a esta IP:

```text
http://192.168.100.70:5000
```

Si tu PC tiene otra IP, cambia `baseUrl` en:

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
