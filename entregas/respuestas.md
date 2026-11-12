# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

La tabla usa partition projection. En Glue no hay una partición registrada por cada día: solo
están las reglas en las propiedades de la tabla (tipo date, formato yyyy-MM-dd, rango del
2026-10-01 al 2026-10-03, intervalo de 1 día y la plantilla de ubicación
s3://<bucket>/entregas/fecha=${fecha}/). Con cada consulta, Athena calcula a partir de esas reglas
qué fechas existen y en qué rutas de S3 buscar.

El 2026-10-03 ya estaba dentro del rango desde el despliegue, pero no tenía archivo, así que no
devolvía filas: en la etapa inicial las consultas daban 12 registros (resultados/inicial/). Al subir
entregas/fecha=2026-10-03/entregas.csv, la partición proyectada encontró el objeto y la tabla pasó a
18 registros (resultados/final/verificacion_total_tabla.csv, ejecución
83b450e2-dd79-451a-8054-84bcf63c68c3). Los 6 registros del día 3 están en
resultados/final/verificacion_tercer_dia.csv (ejecución c314b9bf-923e-43ed-835b-500ee565a735) y los
resultados agregados coinciden con las referencias finales (ejecuciones
ff1fca31-218f-48b2-99db-9c514876c51f y 31d44049-e375-46ae-8069-2cde1073e9e1). No hizo falta ningún
crawler, MSCK REPAIR TABLE, ALTER TABLE ADD PARTITION ni cambiar Terraform.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar?

No aparecería en las consultas. El rango proyectado termina en 2026-10-03, entonces Athena nunca
calcula la fecha 2026-10-04 ni busca en esa ruta, aunque el archivo esté bien ubicado en
entregas/fecha=2026-10-04/entregas.csv. No daría error: simplemente esas filas no se devolverían y
la tabla seguiría mostrando 18 registros.

Para incluirlo habría que ampliar el límite superior del rango, es decir, cambiar
projection.fecha.range a "2026-10-01,2026-10-04" (en mi código, la variable fecha_fin de
infraestructura/variables.tf) y aplicar el cambio con terraform apply. El archivo debe mantener la
misma ruta y el mismo esquema de cinco columnas.
