#!/bin/bash
#SBATCH --job-name=ag_kconv
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=01:00:00
#SBATCH --array=0-4
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail

module purge || true
module load qe
export OMP_NUM_THREADS=1

# Directory where you ran `sbatch` from (and where your templates live)
SUBMIT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"

mkdir -p "${SUBMIT_DIR}/runs" "${SUBMIT_DIR}/logs" "${SUBMIT_DIR}/pseudos"

# ---- cubic k-point meshes to test ----
K=(4 6 8 12 16)

idx=${SLURM_ARRAY_TASK_ID}
nk=${K[$idx]}
label="${nk}x${nk}x${nk}"

echo "Running Ag SCF + DOS for k-mesh ${label}"

workdir="${SUBMIT_DIR}/runs/Ag_${label}"
mkdir -p "${workdir}/tmp/Ag_scan_k"

# ---- build SCF input from template ----
sed -e "s/NK/${nk}/g" \
    "${SUBMIT_DIR}/Ag_scan_k.in.tpl" > "${workdir}/Ag_scan_k.in"

cd "${workdir}"

# ---- run SCF ----
mpirun -np ${SLURM_NTASKS} pw.x -in Ag_scan_k.in > Ag_scan_k.out

# ---- build DOS input from template ----
sed -e "s/NK/${nk}/g" \
    "${SUBMIT_DIR}/Ag_DOS.in.tpl" > Ag_DOS.in

# ---- run DOS ----
dos.x -in Ag_DOS.in > Ag_DOS.out

