#!/bin/bash
set -euo pipefail

for A in 3.80 3.85 3.90 3.95 4.00; do
  in="runs/pt_fcc_A${A}.in"
  out="runs/pt_fcc_A${A}.out"

  # Replace every __A__ token with the numeric value
  sed "s/__A__/${A}/g" pt_fcc_TEMPLATE.in > "$in"

  echo "Running A = $A"
  pw.x -in "$in" > "$out"
done

