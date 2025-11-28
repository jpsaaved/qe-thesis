#!/bin/bash
#SBATCH --job-name=fe_FM      # change NM→FM/AFM when you change SPIN_MODE
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=02:00:00
#SBATCH --array=0-8                    # 0..(N-1), N = number of a-values
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail
SECONDS=0                            # bash timer for this array task

module purge || true
module load qe                       # adjust to your cluster

# ----------------------------
# User settings
# ----------------------------
# Choose which spin state to run: NM, FM, or AFM
SPIN_MODE="FM"                       # <-- change to "NM" or "AFM" as needed

SUBMIT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$SUBMIT_DIR"

mkdir -p logs data tmp inputs outputs

TEMPLATE="fe_bcc_${SPIN_MODE}.in.tpl"   # fe_bcc_NM.in.tpl, fe_bcc_FM.in.tpl, ...

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template '$TEMPLATE' not found" >&2
  exit 1
fi

# ----------------------------
# Read lattice constants
# ----------------------------
# a_list.txt: one value per line (Å); lines starting with '#' are ignored
mapfile -t Avals < <(grep -v '^\s*#' a_list.txt | tr -d '\r')

idx=${SLURM_ARRAY_TASK_ID}
if (( idx < 0 || idx >= ${#Avals[@]} )); then
  echo "Error: SLURM_ARRAY_TASK_ID=${idx} out of range (0..$((${#Avals[@]}-1)))"
  exit 1
fi

A="${Avals[$idx]}"                  # e.g. "2.85"
A_TAG=${A//./p}                     # e.g. 2p85 for filenames

PREFIX="fe_${SPIN_MODE}_a${A_TAG}"
OUTDIR="tmp/${PREFIX}"
INPUT="inputs/fe_bcc_${SPIN_MODE}_a${A_TAG}.in"
OUTPUT="outputs/fe_bcc_${SPIN_MODE}_a${A_TAG}.out"

mkdir -p "$OUTDIR"

echo "Host         : $(hostname)"
echo "Spin mode    : ${SPIN_MODE}"
echo "Lattice a    : ${A} Å (index ${idx})"
echo "PREFIX       : ${PREFIX}"
echo "OUTDIR       : ${OUTDIR}"
echo "INPUT file   : ${INPUT}"
echo "OUTPUT file  : ${OUTPUT}"
echo "Start time   : $(date)"

# ----------------------------
# Build QE input (replace AAAA, PREFIX, OUTDIR)
# ----------------------------
sed -e "s/AAAA/${A}/g" \
    -e "s/PREFIX/${PREFIX}/g" \
    -e "s|OUTDIR|${OUTDIR}|g" \
    "$TEMPLATE" > "$INPUT"

echo "Generated &system A and K_POINTS line:"
grep -E "A\s*=" "$INPUT" || true
grep -A1 "K_POINTS" "$INPUT" || true

# ----------------------------
# Run Quantum ESPRESSO
# ----------------------------
echo "Running pw.x ..."

/usr/bin/time -f "RUNSTATS: %E elapsed, %P CPU, %M KB max RSS" \
  pw.x -in "$INPUT" > "$OUTPUT"

echo "pw.x finished at: $(date)"

# ----------------------------
# Extract final total energy
# ----------------------------
energy_ry=$(grep '!    total energy' "$OUTPUT" | tail -n 1 | awk '{print $5}')

if [[ -z "$energy_ry" ]]; then
  echo "WARNING: Could not extract total energy from $OUTPUT" >&2
else
  datafile="data/fe_${SPIN_MODE}_E_vs_a.dat"
  echo "${A} ${energy_ry}" >> "$datafile"
  echo "Appended: a=${A} Å  E=${energy_ry} Ry  -> ${datafile}"
fi

echo "Total task elapsed (bash SECONDS): ${SECONDS} seconds"
echo "Done."
