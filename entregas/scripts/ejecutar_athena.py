#!/usr/bin/env python3
"""Ejecuta las consultas de un archivo .sql en Athena (workgroup del ejercicio),
guarda cada resultado como CSV y registra la ejecución en
evidencias/ejecuciones_athena.csv.

Uso (desde la raíz del repositorio):
  python3 scripts/ejecutar_athena.py --etapa inicial \
      --sql consultas/intentos_por_fecha_estado.sql \
      --salidas resultados/inicial/intentos_por_fecha_estado.csv

Si el .sql tiene varias consultas separadas por ';', se pasa una salida por consulta.
Solo usa la biblioteca estándar y la AWS CLI.
"""
import argparse
import csv
import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
REGISTRO = RAIZ / "evidencias" / "ejecuciones_athena.csv"


def aws(*args):
    r = subprocess.run(["aws", *args], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"Error en aws {' '.join(args[:2])}: {r.stderr.strip()}")
    return r.stdout


def separar_consultas(texto):
    consultas = []
    for bloque in texto.split(";"):
        lineas = [l for l in bloque.splitlines() if l.strip() and not l.strip().startswith("--")]
        if lineas:
            consultas.append("\n".join(lineas))
    return consultas


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--etapa", required=True, choices=["inicial", "final"])
    p.add_argument("--sql", required=True)
    p.add_argument("--salidas", required=True, nargs="+")
    a = p.parse_args()

    salidas = json.loads((RAIZ / "evidencias" / "outputs.json").read_text())
    region = salidas["region"]["value"]
    bucket = salidas["bucket"]["value"]
    base = salidas["base_de_datos"]["value"]
    wg = salidas["workgroup"]["value"]

    consultas = separar_consultas((RAIZ / a.sql).read_text())
    if len(consultas) != len(a.salidas):
        sys.exit(f"El .sql tiene {len(consultas)} consulta(s) y diste {len(a.salidas)} salida(s).")

    nuevo = not REGISTRO.exists()
    with REGISTRO.open("a", newline="") as f:
        w = csv.writer(f)
        if nuevo:
            w.writerow(["etapa", "archivo_sql", "id_ejecucion", "archivo_resultado"])
        for consulta, salida in zip(consultas, a.salidas):
            qid = aws("athena", "start-query-execution", "--region", region,
                      "--work-group", wg, "--query-string", consulta,
                      "--query-execution-context", f"Database={base}",
                      "--query", "QueryExecutionId", "--output", "text").strip()
            while True:
                estado = aws("athena", "get-query-execution", "--region", region,
                             "--query-execution-id", qid,
                             "--query", "QueryExecution.Status.State", "--output", "text").strip()
                if estado in ("SUCCEEDED", "FAILED", "CANCELLED"):
                    break
                time.sleep(1)
            if estado != "SUCCEEDED":
                motivo = aws("athena", "get-query-execution", "--region", region,
                             "--query-execution-id", qid,
                             "--query", "QueryExecution.Status.StateChangeReason", "--output", "text")
                sys.exit(f"La consulta {qid} terminó en {estado}: {motivo}")

            with tempfile.TemporaryDirectory() as tmp:
                destino = Path(tmp) / "r.csv"
                aws("s3", "cp", f"s3://{bucket}/resultados-athena/{qid}.csv", str(destino), "--region", region)
                filas = list(csv.reader(destino.read_text().splitlines()))
            ruta = RAIZ / salida
            ruta.parent.mkdir(parents=True, exist_ok=True)
            # Athena entrega los CSV con comillas; se reescriben sin comillas
            # (los valores no contienen comas) para compararlos con las referencias.
            ruta.write_text("".join(",".join(fila) + "\n" for fila in filas))
            w.writerow([a.etapa, a.sql, qid, salida])
            f.flush()
            print(f"OK {a.sql} -> {salida}  (id {qid}, {len(filas) - 1} filas)")


if __name__ == "__main__":
    main()
