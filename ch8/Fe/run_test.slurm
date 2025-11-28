#!/bin/bash
#SBATCH --job-name=fe_mag
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=01:00:00
#SBATCH --array=0-8
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail

module purge || true
module load qe
export OMP_NUM_THREADS=1

SPIN_MODE="AFM"

# Directory where you ran `sbatch` from (and where your templates live)
SUBMIT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"

mkdir -p "${SUBMIT_DIR}/runs" "${SUBMIT_DIR}/logs" "${SUBMIT_DIR}/pseudos"

TEMPLATE_NM="fe_bcc_NM.in.tpl"
TEMPLATE_FM="fe_bcc_FM.in.tpl"
TEMPLATE_AFM="fe_bcc_AFM.in.tpl"


mapfile -t Avals < <(grep -v '^\s*#' a_list.txt | tr -d '\r')
idx=${SLURM_ARRAY_TASK_ID}
A=${Avals[$idx]}
A_TAG=${A//./p}

case "$SPIN_MODE" in
  "NM")  TEMPLATE="$TEMPLATE_NM"  ;;
  "FM")  TEMPLATE="$TEMPLATE_FM"  ;;
  "AFM") TEMPLATE="$TEMPLATE_AFM" ;;
  *) echo "Unknown SPIN_MODE '$SPIN_MODE'"; exit 1 ;;
esac

PREFIX="fe_${SPIN_MODE}_a${A_TAG}"
INPUT="inputs/fe_bcc_${SPIN_MODE}_a${A_TAG}.in"
OUTPUT="data/${PREFIX}.out"

sed -e "s/AAAA/${A}/g" \
    -e "s/PREFIX/${PREFIX}/g" \
    "$TEMPLATE" > "$INPUT"

echo "Host: $(hostname)"
echo "SPIN_MODE=$SPIN_MODE a=$A PREFIX=$PREFIX"

# *** no srun, no MPI here ***
pw.x < "$INPUT" > "$OUTPUT"

# Grab the *last* '!    total energy' line and take the 5th column (in Ry)
energy_ry=$(grep '!    total energy' "${OUTPUT}" | tail -n 1 | awk '{print $5}')
if [[ -n "$energy_ry" ]]; then
  echo "$A $energy_ry" >> "data/fe_${SPIN_MODE}_E_vs_a.dat"
fi
