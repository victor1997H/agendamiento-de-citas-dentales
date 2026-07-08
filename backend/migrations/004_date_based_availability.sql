ALTER TABLE disponibilidad_odontologos ADD COLUMN IF NOT EXISTS fecha DATE;

UPDATE disponibilidad_odontologos
SET dia_semana = 7
WHERE dia_semana = 0;

ALTER TABLE disponibilidad_odontologos
DROP CONSTRAINT IF EXISTS disponibilidad_odontologos_dia_semana_check;

ALTER TABLE disponibilidad_odontologos
DROP CONSTRAINT IF EXISTS chk_disponibilidad_dia_semana;

ALTER TABLE disponibilidad_odontologos
ADD CONSTRAINT chk_disponibilidad_dia_semana CHECK (dia_semana BETWEEN 1 AND 7);

ALTER TABLE disponibilidad_odontologos
DROP CONSTRAINT IF EXISTS disponibilidad_odontologos_doctor_id_dia_semana_hora_inicio_hora_fin_key;

ALTER TABLE disponibilidad_odontologos
DROP CONSTRAINT IF EXISTS uq_disponibilidad_bloque;

DROP INDEX IF EXISTS ux_disponibilidad_fecha_bloque;
DROP INDEX IF EXISTS ux_disponibilidad_semanal_bloque;

CREATE UNIQUE INDEX IF NOT EXISTS ux_disponibilidad_fecha_bloque
ON disponibilidad_odontologos(doctor_id, fecha, hora_inicio, hora_fin)
WHERE fecha IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_disponibilidad_semanal_bloque
ON disponibilidad_odontologos(doctor_id, dia_semana, hora_inicio, hora_fin)
WHERE fecha IS NULL;
