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
module load qe      # adjust as needed
# If no modules:
# export PATH=/path/to/qe/bin:$PATH

# -----------------------------
# User settings
# -----------------------------
SPIN_MODE="AFM"                # options: NM, FM, AFM
TEMPLATE_IN="fe_bcc_${SPIN_MODE}.in"

mkdir -p tmp runs logs data

# -----------------------------
# Read lattice constants
# -----------------------------
# a_list.txt should contain one value per line (ignore lines starting with #)
Avals=($(grep -v '^#' a_list.txt | tr -d '\r'))

idx=${SLURM_ARRAY_TASK_ID}
if (( idx < 0 || idx >= ${#Avals[@]} )); then
  echo "Error: SLURM_ARRAY_TASK_ID=${idx} out of range (0..$((${#Avals[@]}-1)))"
  exit 1
fi

A=${Avals[$idx]}          # lattice constant in Å as string, e.g. "2.85"
A_TAG=${A//./p}           # for filenames, e.g. "2p85"

echo "Running ${SPIN_MODE} bcc Fe for a = ${A} Å (index ${idx})"

# -----------------------------
# Build per-a QE input file
# -----------------------------
INPUT="fe_bcc_${SPIN_MODE}_a${A_TAG}.in"

# We modify:
#  - the A = ... line
#  - the prefix = 'fe_X' line
#  - the outdir = './tmp/fe_X' line
sed \
  -e "s/^\(\s*A\s*=\s*\).*/\1${A},/" \
  -e "s/^\(\s*prefix\s*=\s*'\)fe_${SPIN_MODE}\('.*\)/\1fe_${SPIN_MODE}_a${A_TAG}\2/" \
  -e "s|^\(\s*outdir\s*=\s*'\)\./tmp/fe_${SPIN_MODE}\('.*\)|\1./tmp/fe_${SPIN_MODE}_a${A_TAG}\2|" \
  "${TEMPLATE_IN}" > "${INPUT}"

# Make sure the per-a outdir exists (matches what we just put into the input)
OUTDIR="./tmp/fe_${SPIN_MODE}_a${A_TAG}"
mkdir -p "${OUTDIR}"

# -----------------------------
# Run QE
# -----------------------------
OUTFILE="runs/fe_${SPIN_MODE}_a${A_TAG}.out"
echo "Running pw.x < ${INPUT} > ${OUTFILE}"
pw.x < "${INPUT}" > "${OUTFILE}"


# -----------------------------
# Aggregate total energies
# -----------------------------
# Grab the first '!    total energy' line and take the 5th column (in Ry)
energy_ry=$(grep -m1 '!    total energy' "${OUTFILE}" | awk '{print $5}')

if [[ -z "${energy_ry}" ]]; then
  echo "WARNING: Could not extract total energy from ${OUTFILE}" >&2
else
  datafile="data/fe_${SPIN_MODE}_E_vs_a.dat"
  # Append: a(Angstrom)   E_total(Ry)
  echo "${A} ${energy_ry}" >> "${datafile}"
  echo "Appended: a=${A}  E=${energy_ry} Ry  -> ${datafile}"
fi
