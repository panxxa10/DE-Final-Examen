# Entregas: S3 + Glue + Athena con partition projection (Terraform)

Consulta de intentos de entrega de paquetes desde Athena sobre CSV en S3. Las fechas nuevas se
consultan sin crawlers ni registrar particiones, gracias a *partition projection*.

```
CSV -> S3 (entregas/) -> Tabla externa en Glue (partition projection) -> Athena -> S3 (resultados-athena/)
```

## 1. Prerrequisitos

- macOS con Terminal, Python 3, Git.
- AWS CLI v2 y Terraform >= 1.5 instalados.
- Credenciales de AWS configuradas **fuera del repositorio** (`aws configure`).
  Verificación: `aws sts get-caller-identity`.
- Región usada: `us-east-1` (variable `region` en `infraestructura/variables.tf`).
- Permisos sobre S3, Glue Data Catalog y Athena.

Archivos de entrada (no se modifican): `data/entregas/fecha=YYYY-MM-DD/entregas.csv`.
Referencias: `resultados_esperados/` (no se suben a S3).

## 2. Despliegue de la infraestructura

Desde la raíz del repositorio:

```bash
cd infraestructura
terraform init
terraform apply -auto-approve -no-color 2>&1 | tee ../evidencias/aplicacion_terraform.txt
terraform output -json > ../evidencias/outputs.json
cd ..
```

Recursos creados: bucket S3 privado (con bloqueo de acceso público), base de datos de Glue, tabla
externa con partition projection (formato `yyyy-MM-dd`, rango `2026-10-01` a `2026-10-03`, intervalo de
1 día) y workgroup de Athena con resultados en `s3://<bucket>/resultados-athena/`.

Variable de shell usada en los siguientes pasos:

```bash
BUCKET=$(python3 -c "import json;print(json.load(open('evidencias/outputs.json'))['bucket']['value'])")
```

## 3. Etapa inicial: días 1 y 2

Se cargan **solo** estos dos archivos, uno por uno:

```bash
aws s3 cp data/entregas/fecha=2026-10-01/entregas.csv s3://$BUCKET/entregas/fecha=2026-10-01/entregas.csv
aws s3 cp data/entregas/fecha=2026-10-02/entregas.csv s3://$BUCKET/entregas/fecha=2026-10-02/entregas.csv
aws s3 ls s3://$BUCKET/entregas/ --recursive
```

Consultas (cada ejecución queda en `evidencias/ejecuciones_athena.csv`):

```bash
python3 scripts/ejecutar_athena.py --etapa inicial --sql consultas/intentos_por_fecha_estado.sql --salidas resultados/inicial/intentos_por_fecha_estado.csv
python3 scripts/ejecutar_athena.py --etapa inicial --sql consultas/porcentaje_exito_por_fecha_ciudad.sql --salidas resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv
python3 scripts/ejecutar_athena.py --etapa inicial --sql consultas/duracion_promedio_2026-10-02.sql --salidas resultados/inicial/duracion_promedio_2026-10-02.csv
bash scripts/comparar.sh inicial
```

## 4. Etapa final: nueva fecha (día 3)

Sin tocar la infraestructura ni la tabla, solo se sube el archivo y se consulta:

```bash
aws s3 cp data/entregas/fecha=2026-10-03/entregas.csv s3://$BUCKET/entregas/fecha=2026-10-03/entregas.csv

python3 scripts/ejecutar_athena.py --etapa final --sql consultas/verificacion_tercer_dia.sql \
  --salidas resultados/final/verificacion_tercer_dia.csv resultados/final/verificacion_total_tabla.csv resultados/final/verificacion_conteo_estados_dia3.csv
python3 scripts/ejecutar_athena.py --etapa final --sql consultas/intentos_por_fecha_estado.sql --salidas resultados/final/intentos_por_fecha_estado.csv
python3 scripts/ejecutar_athena.py --etapa final --sql consultas/porcentaje_exito_por_fecha_ciudad.sql --salidas resultados/final/porcentaje_exito_por_fecha_ciudad.csv
bash scripts/comparar.sh final
```

No se ejecutó ningún crawler, `MSCK REPAIR TABLE`, `ALTER TABLE ADD PARTITION` ni se cambió el rango.
Resultado de la verificación: 6 registros del 2026-10-03 y 18 registros en total.

## 5. Evidencias

| Archivo | Contenido |
| --- | --- |
| `evidencias/aplicacion_terraform.txt` | Salida de `terraform apply` |
| `evidencias/outputs.json` | Bucket, base de datos, tabla, workgroup y región |
| `evidencias/ejecuciones_athena.csv` | Etapa, SQL, id de ejecución de Athena y archivo de resultado |
| `evidencias/eliminacion_terraform.txt` | Salida de `terraform destroy` |

## 6. Limpieza

Primero se guardan todas las evidencias. Luego, desde la raíz:

```bash
cd infraestructura
terraform destroy -auto-approve -no-color 2>&1 | tee ../evidencias/eliminacion_terraform.txt
cd ..
```

El bucket se crea con `force_destroy = true`, por lo que Terraform lo vacía (datos y resultados de
Athena) antes de eliminarlo. El workgroup también se elimina con sus consultas.

## 7. Estructura

```
README.md  .gitignore  respuestas.md
infraestructura/  principal.tf  variables.tf  salidas.tf
consultas/        *.sql
resultados/       inicial/  final/
evidencias/
scripts/          ejecutar_athena.py  comparar.sh
data/  resultados_esperados/
```

No se publican credenciales ni archivos de estado de Terraform (ver `.gitignore`).
