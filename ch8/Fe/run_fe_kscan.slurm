#!/bin/bash
#SBATCH --job-name=fe_kscan
#SBATCH --nodes=1
#SBATCH --ntasks=1                 # serial to avoid I/O races
#SBATCH --time=01:30:00
#SBATCH --array=0-10               # 11 values in NK_LIST
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail
SECONDS=0                           # bash timer for this task

module purge || true
module load qe                      # adjust to your cluster

SUBMIT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$SUBMIT_DIR"

mkdir -p logs data tmp inputs

TEMPLATE="fe_kscan.in.tpl"

# ---- k-point meshes to scan ----
NK_LIST=(4 6 8 10 12 14 16 18 20 22 24)

idx=${SLURM_ARRAY_TASK_ID}
if (( idx < 0 || idx >= ${#NK_LIST[@]} )); then
  echo "Error: SLURM_ARRAY_TASK_ID=${idx} out of range"
  exit 1
fi

NK=${NK_LIST[$idx]}

PREFIX="fe_FM_NK${NK}"
OUTDIR="tmp/${PREFIX}"              # unique scratch dir
INPUT="inputs/fe_kscan_NK${NK}.in"
OUTPUT="data/fe_kscan_NK${NK}.out"

mkdir -p "$OUTDIR"

echo "Host        : $(hostname)"
echo "NK          : ${NK}"
echo "PREFIX      : ${PREFIX}"
echo "OUTDIR      : ${OUTDIR}"
echo "INPUT file  : ${INPUT}"
echo "OUTPUT file : ${OUTPUT}"
echo "Start time  : $(date)"

# ---- build QE input (replace PREFIX, OUTDIR, NK) ----
if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template '$TEMPLATE' not found" >&2
  exit 1
fi

sed -e "s/PREFIX/${PREFIX}/g" \
    -e "s|OUTDIR|${OUTDIR}|g" \
    -e "s/\bNK\b/${NK}/g" \
    "$TEMPLATE" > "$INPUT"

echo "Generated K_POINTS line:"
grep -A1 "K_POINTS" "$INPUT" || true

# ---- run QE with CPU/time stats ----
echo "Running pw.x ..."

/usr/bin/time -f "RUNSTATS: %E elapsed, %P CPU, %M KB max RSS" \
  pw.x -in "$INPUT" > "$OUTPUT"

echo "pw.x finished at: $(date)"

# ---- extract FINAL total energy ----
energy_ry=$(grep '!    total energy' "$OUTPUT" | tail -n 1 | awk '{print $5}')

if [[ -z "$energy_ry" ]]; then
  echo "WARNING: Could not extract total energy from $OUTPUT" >&2
else
  # Use an *unsorted* file; we'll sort it later
  datafile="data/fe_kscan_E_vs_NK_unsorted.dat"
  echo "${NK} ${energy_ry}" >> "$datafile"
  echo "Appended: NK=${NK}  E=${energy_ry} Ry -> ${datafile}"
fi

echo "Total task elapsed (bash SECONDS): ${SECONDS} seconds"
echo "Done."

