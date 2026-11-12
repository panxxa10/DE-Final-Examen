-- Cantidad de intentos por fecha y estado (se cuentan todos los intentos)
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas_db.entregas
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
