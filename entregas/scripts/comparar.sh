#!/usr/bin/env bash
# Compara los resultados obtenidos en Athena con las referencias suministradas.
# Uso: bash scripts/comparar.sh inicial   |   bash scripts/comparar.sh final
set -u
cd "$(dirname "$0")/.."
etapa="${1:?Uso: bash scripts/comparar.sh inicial|final}"
par() { # obtenido esperado
  if diff -q "$1" "$2" >/dev/null; then echo "IGUAL      $1"; else echo "DIFERENTE  $1"; diff "$1" "$2"; fi
}
par "resultados/$etapa/intentos_por_fecha_estado.csv"          "resultados_esperados/intentos_por_fecha_estado_$etapa.csv"
par "resultados/$etapa/porcentaje_exito_por_fecha_ciudad.csv"  "resultados_esperados/porcentaje_exito_por_fecha_ciudad_$etapa.csv"
if [ "$etapa" = "inicial" ]; then
  par "resultados/inicial/duracion_promedio_2026-10-02.csv"    "resultados_esperados/duracion_promedio_2026-10-02.csv"
fi
