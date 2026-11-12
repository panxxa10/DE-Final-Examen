-- Verificación del tercer día (2026-10-03). Son tres consultas independientes,
-- separadas por punto y coma. El script scripts/ejecutar_athena.py las ejecuta
-- en orden y guarda un CSV por cada una:
--   1) resultados/final/verificacion_tercer_dia.csv          (los 6 registros)
--   2) resultados/final/verificacion_total_tabla.csv          (total = 18)
--   3) resultados/final/verificacion_conteo_estados_dia3.csv  (conteo por estado)

SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

SELECT
    COUNT(*) AS total_registros
FROM entregas_db.entregas;

SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;
