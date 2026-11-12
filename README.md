# Examen final: Ingeniería de Datos (2026-2)

Entrega de los dos ejercicios del examen final.

| Carpeta | Ejercicio | Tecnologías |
| --- | --- | --- |
| [`ventas/`](ventas/) | Resumen diario de ventas con control de frescura de la fuente | dbt, Airflow, DuckDB, Docker |
| [`entregas/`](entregas/) | Consulta de entregas por fecha sin registrar particiones | Terraform, S3, Glue, Athena (partition projection) |

## ventas/

- `DE-Final-Ventas-main/`: proyecto del examen. Solo se modificaron `dbt/models/ventas_diarias.sql`,
  `dbt/models/sources.yml` y `airflow/dags/examen_ventas.py`.
- `evidencias_examen/`: capturas de las ejecuciones (fuente actualizada y desactualizada), log del fallo de
  freshness y documento con las respuestas conceptuales.

## entregas/

Instrucciones reproducibles (prerrequisitos, despliegue, orden de carga, consultas y limpieza) en
[`entregas/README.md`](entregas/README.md). Los comandos de ese README se ejecutan desde la carpeta
`entregas/`. Evidencias en `entregas/evidencias/` y respuestas en `entregas/respuestas.md`.

## Seguridad

No se publican credenciales, archivos `.env` ni archivos de estado de Terraform. La infraestructura de AWS
fue eliminada con `terraform destroy` (evidencia en `entregas/evidencias/eliminacion_terraform.txt`).

## Hilo Claude
https://claude.ai/share/e7b59cdc-244f-4a21-9752-7b1fd0063bfa
