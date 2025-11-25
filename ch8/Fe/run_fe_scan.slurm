#!/bin/bash
#SBATCH --job-name=fe_bcc_FM_scan
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=02:00:00
#SBATCH --array=0-8
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail
export OMP_NUM_THREADS=1

module purge || true
module load qe      # adjust to your module name

# ==========================
# User settings
# ==========================

# Choose spin state for this batch submit: NM, FM, or AFM
SPIN_MODE="NM"

# Template file names (must be in the working directory)
TEMPLATE_NM="fe_bcc_NM.in"
TEMPLATE_FM="fe_bcc_FM.in"
TEMPLATE_AFM="fe_bcc_AFM.in"

mkdir -p tmp logs data

# ==========================
# Read lattice constants
# ==========================

# a_list.txt: one value per line, comments allowed with '#'
mapfile -t Avals < <(grep -v '^\s*#' a_list.txt | tr -d '\r')

idx=${SLURM_ARRAY_TASK_ID}
if (( idx < 0 || idx >= ${#Avals[@]} )); then
    echo "Error: SLURM_ARRAY_TASK_ID=${idx} out of range (0..$((${#Avals[@]}-1)))"
    exit 1
fi

A=${Avals[$idx]}              # e.g. "2.85"
A_TAG=${A//./p}               # e.g. "2p85" for filenames

echo "Running $SPIN_MODE bcc Fe for a = $A Å (index $idx)"

# ==========================
# Pick template by spin mode
# ==========================

case "$SPIN_MODE" in
  "NM")  TEMPLATE="$TEMPLATE_NM"  ;;
  "FM")  TEMPLATE="$TEMPLATE_FM"  ;;
  "AFM") TEMPLATE="$TEMPLATE_AFM" ;;
  *) echo "Unknown SPIN_MODE '$SPIN_MODE' (use NM/FM/AFM)"; exit 1 ;;
esac

# ==========================
# Build QE input
# ==========================

PREFIX="fe_${SPIN_MODE}_a${A_TAG}"
OUTDIR="./tmp/${PREFIX}"
INPUT="fe_bcc_${SPIN_MODE}_a${A_TAG}.in"
OUTPUT="data/${PREFIX}.out"

mkdir -p "$OUTDIR"

# Replace AAAA, PREFIX, OUTDIR in the template
sed -e "s/AAAA/${A}/g" \
    -e "s/PREFIX/${PREFIX}/g" \
    -e "s|OUTDIR|${OUTDIR}|g" \
    "$TEMPLATE" > "$INPUT"

# ==========================
# Run Quantum ESPRESSO
# ==========================

echo "Running pw.x with input $INPUT"
srun pw.x -in "$INPUT" > "$OUTPUT"

# -----------------------------
# Aggregate total energies
# -----------------------------
# Grab the first '!    total energy' line and take the 5th column (in Ry)
energy_ry=$(grep -m1 '!    total energy' "${OUTPUT}" | awk '{print $5}')

if [[ -z "${energy_ry}" ]]; then
  echo "WARNING: Could not extract total energy from ${OUTPUT}" >&2
else
  datafile="data/fe_${SPIN_MODE}_E_vs_a.dat"
  # Append: a(Angstrom)   E_total(Ry)
  echo "${A} ${energy_ry}" >> "${datafile}"
  echo "Appended: a=${A}  E=${energy_ry} Ry  -> ${datafile}"
fi
