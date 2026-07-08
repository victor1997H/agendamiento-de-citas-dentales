CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    telefono VARCHAR(40) NOT NULL,
    password_hash TEXT NOT NULL,
    rol VARCHAR(20) NOT NULL DEFAULT 'usuario',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS telefono VARCHAR(40);
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS rol VARCHAR(20) NOT NULL DEFAULT 'usuario';
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT NOW();

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'usuarios' AND column_name = 'es_admin'
    ) THEN
        UPDATE usuarios
        SET rol = CASE WHEN es_admin THEN 'admin' ELSE COALESCE(NULLIF(rol, ''), 'usuario') END;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS odontologos (
    id SERIAL PRIMARY KEY,
    usuario_id BIGINT UNIQUE REFERENCES usuarios(id) ON DELETE SET NULL,
    nombre VARCHAR(120) NOT NULL UNIQUE,
    especialidad VARCHAR(120) NOT NULL DEFAULT 'Odontólogo General',
    telefono VARCHAR(40),
    rating NUMERIC(2,1) NOT NULL DEFAULT 5.0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS servicios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL UNIQUE,
    descripcion TEXT,
    duracion_minutos INTEGER NOT NULL DEFAULT 45,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS citas (
    id SERIAL PRIMARY KEY,
    usuario_id BIGINT REFERENCES usuarios(id) ON DELETE CASCADE,
    doctor_id BIGINT REFERENCES odontologos(id) ON DELETE SET NULL,
    servicio_id BIGINT REFERENCES servicios(id) ON DELETE SET NULL,
    paciente VARCHAR(120) NOT NULL,
    servicio VARCHAR(120) NOT NULL DEFAULT 'Consulta Dental',
    fecha TIMESTAMP NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
    notas TEXT,
    local_uuid UUID,
    sincronizado BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

ALTER TABLE citas ADD COLUMN IF NOT EXISTS usuario_id BIGINT REFERENCES usuarios(id) ON DELETE CASCADE;
ALTER TABLE citas ADD COLUMN IF NOT EXISTS doctor_id BIGINT REFERENCES odontologos(id) ON DELETE SET NULL;
ALTER TABLE citas ADD COLUMN IF NOT EXISTS servicio_id BIGINT REFERENCES servicios(id) ON DELETE SET NULL;
ALTER TABLE citas ADD COLUMN IF NOT EXISTS servicio VARCHAR(120) NOT NULL DEFAULT 'Consulta Dental';
ALTER TABLE citas ADD COLUMN IF NOT EXISTS notas TEXT;
ALTER TABLE citas ADD COLUMN IF NOT EXISTS local_uuid UUID;
ALTER TABLE citas ADD COLUMN IF NOT EXISTS sincronizado BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE citas ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE citas ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT NOW();

CREATE TABLE IF NOT EXISTS disponibilidad_odontologos (
    id SERIAL PRIMARY KEY,
    doctor_id BIGINT NOT NULL REFERENCES odontologos(id) ON DELETE CASCADE,
    dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (doctor_id, dia_semana, hora_inicio, hora_fin)
);

CREATE TABLE IF NOT EXISTS notificaciones (
    id SERIAL PRIMARY KEY,
    usuario_id BIGINT REFERENCES usuarios(id) ON DELETE CASCADE,
    cita_id BIGINT REFERENCES citas(id) ON DELETE CASCADE,
    titulo VARCHAR(120) NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS password_reset_codes (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL,
    reset_token_hash TEXT,
    attempts INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    token_expires_at TIMESTAMPTZ,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO servicios(nombre, descripcion, duracion_minutos)
VALUES
    ('Limpieza Dental', 'Profilaxis y limpieza dental preventiva', 45),
    ('Blanqueamiento', 'Tratamiento estético de blanqueamiento dental', 60),
    ('Control Dental', 'Revisión odontológica general', 30),
    ('Ortodoncia', 'Control y seguimiento de ortodoncia', 60),
    ('Consulta General', 'Consulta odontológica inicial', 30)
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO odontologos(nombre, especialidad, telefono, rating)
VALUES ('Dr. Roberto Méndez', 'Odontólogo General', '0999999999', 5.0)
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO disponibilidad_odontologos(doctor_id, dia_semana, hora_inicio, hora_fin)
SELECT id, dia, TIME '08:00', TIME '17:00'
FROM odontologos
CROSS JOIN generate_series(1, 5) AS dia
WHERE nombre = 'Dr. Roberto Méndez'
ON CONFLICT (doctor_id, dia_semana, hora_inicio, hora_fin) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);
CREATE INDEX IF NOT EXISTS idx_citas_usuario_id ON citas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_citas_doctor_id ON citas(doctor_id);
CREATE INDEX IF NOT EXISTS idx_citas_fecha ON citas(fecha);
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario ON notificaciones(usuario_id, leida);
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_user_active
ON password_reset_codes(user_id, used_at, created_at DESC);

DROP INDEX IF EXISTS ux_citas_doctor_fecha_activas;
CREATE UNIQUE INDEX IF NOT EXISTS ux_citas_doctor_fecha_activas
ON citas(doctor_id, fecha)
WHERE doctor_id IS NOT NULL AND estado NOT IN ('cancelada', 'no_asistio');
