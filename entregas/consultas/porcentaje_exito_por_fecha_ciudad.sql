-- Porcentaje de entregas exitosas por fecha y ciudad.
-- Numerador: solo 'entregado'. Denominador: todos los intentos del grupo.
-- Se usa DOUBLE para evitar la división entera.
SELECT
    fecha,
    ciudad,
    ROUND(CAST(100 AS DOUBLE) * COUNT_IF(estado = 'entregado') / COUNT(*), 2) AS porcentaje_exito
FROM entregas_db.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
