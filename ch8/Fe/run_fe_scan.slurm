#!/bin/bash
#SBATCH --job-name=fe_bcc_scan_NM      # change NM→FM/AFM when you change SPIN_MODE
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=02:00:00
#SBATCH --array=0-8                    # 0..(N-1), N = number of a-values
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail
export OMP_NUM_THREADS=1

module purge || true
module load qe                         # adjust to your QE module name

# -------- choose which spin state this job runs --------
SPIN_MODE="FM"   # or "FM" or "AFM"

SUBMIT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$SUBMIT_DIR"

mkdir -p logs data tmp inputs

TEMPLATE_NM="fe_bcc_NM.in.tpl"
TEMPLATE_FM="fe_bcc_FM.in.tpl"
TEMPLATE_AFM="fe_bcc_AFM.in.tpl"

# -------- read lattice constants from a_list.txt --------
mapfile -t Avals < <(grep -v '^\s*#' a_list.txt | tr -d '\r')

idx=${SLURM_ARRAY_TASK_ID}
if (( idx < 0 || idx >= ${#Avals[@]} )); then
  echo "Error: SLURM_ARRAY_TASK_ID=${idx} out of range (0..$((${#Avals[@]}-1)))"
  exit 1
fi

A=${Avals[$idx]}           # e.g. "2.85"
A_TAG=${A//./p}            # e.g. "2p85"

case "$SPIN_MODE" in
  "NM")  TEMPLATE="$TEMPLATE_NM"  ;;
  "FM")  TEMPLATE="$TEMPLATE_FM"  ;;
  "AFM") TEMPLATE="$TEMPLATE_AFM" ;;
  *) echo "Unknown SPIN_MODE '$SPIN_MODE' (use NM/FM/AFM)"; exit 1 ;;
esac

PREFIX="fe_${SPIN_MODE}_a${A_TAG}"
INPUT="inputs/fe_bcc_${SPIN_MODE}_a${A_TAG}.in"
OUTPUT="data/${PREFIX}.out"

echo "Host: $(hostname)"
echo "SPIN_MODE = $SPIN_MODE"
echo "a = $A Å (index $idx)"
echo "PREFIX = $PREFIX"

# -------- generate QE input by replacing AAAA and PREFIX --------
sed -e "s/AAAA/${A}/g" \
    -e "s/PREFIX/${PREFIX}/g" \
    "$TEMPLATE" > "$INPUT"

# -------- run Quantum ESPRESSO --------
echo "Running pw.x ..."
srun pw.x < "$INPUT" > "$OUTPUT"
echo "Finished pw.x"

# -------- extract and store total energy --------
energy_ry=$(grep -m1 '!    total energy' "$OUTPUT" | awk '{print $5}')

if [[ -z "$energy_ry" ]]; then
  echo "WARNING: Could not extract total energy from $OUTPUT" >&2
else
  datafile="data/fe_${SPIN_MODE}_E_vs_a.dat"
  echo "$A $energy_ry" >> "$datafile"
  echo "Appended: a=$A  E=$energy_ry Ry -> $datafile"
fi

