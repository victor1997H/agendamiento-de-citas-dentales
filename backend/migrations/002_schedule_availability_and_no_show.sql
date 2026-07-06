CREATE TABLE IF NOT EXISTS disponibilidad_odontologos (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER NOT NULL REFERENCES odontologos(id) ON DELETE CASCADE,
    dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_disponibilidad_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT uq_disponibilidad_bloque UNIQUE (doctor_id, dia_semana, hora_inicio, hora_fin)
);

INSERT INTO disponibilidad_odontologos(doctor_id, dia_semana, hora_inicio, hora_fin)
SELECT id, dia, TIME '08:00', TIME '17:00'
FROM odontologos
CROSS JOIN generate_series(1, 5) AS dia
WHERE nombre = 'Dr. Roberto Méndez'
ON CONFLICT (doctor_id, dia_semana, hora_inicio, hora_fin) DO NOTHING;

DROP INDEX IF EXISTS ux_citas_doctor_fecha_activas;

CREATE UNIQUE INDEX IF NOT EXISTS ux_citas_doctor_fecha_activas
ON citas(doctor_id, fecha)
WHERE doctor_id IS NOT NULL AND estado NOT IN ('cancelada', 'no_asistio');
