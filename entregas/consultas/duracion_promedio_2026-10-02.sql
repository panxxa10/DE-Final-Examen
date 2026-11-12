-- Duración promedio de las entregas exitosas del 2026-10-02.
-- Se filtra estado = 'entregado' para no incluir los ceros de los fallos.
SELECT
    fecha,
    ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2) AS duracion_promedio_minutos
FROM entregas_db.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
