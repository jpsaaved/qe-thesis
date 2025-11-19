#!/bin/bash
#SBATCH --job-name=scal_b1_scan
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=02:00:00
#SBATCH --array=0-11
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail
export OMP_NUM_THREADS=1

# --- Load Quantum ESPRESSO (if your cluster provides a module) ---
module purge; module load qe

# --- Or set the path directly (works on your system) ---
# export PATH=/apps/pkg/qe/7.3/intel/bin:$PATH

# --- Directory setup ---
mkdir -p runs tmp logs

# --- Link pseudopotentials (adjust path to your pslibrary) ---
# ln -sf /users/jsaaved1/research/pslibrary.1.0.0/pbe/PSEUDOPOTENTIALS/* pseudos_PBE/ 2>/dev/null || true

# --- Read lattice constants from list ---
mapfile -t Avals < <(grep -v '^\s*#' a_list_B1.txt | tr -d '\r')
A=${Avals[$SLURM_ARRAY_TASK_ID]}

tag=$(printf "scal_b1_a%.3f" "$A")
in="runs/${tag}.in"
out="runs/${tag}.out"

# --- Generate input from your existing template ---
# Replaces AAAA with numeric lattice constant
awk -v AAAA="$A" '{gsub(/AAAA/, AAAA); print}' ScAl_B1.in.tpl > "$in"

echo "[$(date)] Starting calculation for a = $A Å → $in"

# --- Run QE ---
srun pw.x -in "$in"  > "$out" 2>&1

# Last '! total energy = ... Ry'
F=$(awk '/^[[:space:]]*!?[[:space:]]*total[[:space:]]+energy[[:space:]]*=/{val=$(NF-1)} END{print val}' "$out")

# Last 'smearing contrib. (-TS) = ... Ry'  → store +TS
TS=$(awk '/smearing contrib/{for(i=1;i<=NF;i++) if($i=="=") x=$(i+1)} END{if(x!="") printf "%.12f", -x}' "$out")

# E = F + TS  (write NaN if missing)
E=$(awk -v f="$F" -v ts="$TS" 'BEGIN{
  if (f=="" || ts=="") print "NaN";
  else printf "%.12f", (f+ts);
}')

V=$(awk -v a="$A" 'BEGIN{printf "%.10f", a*a*a}')
printf "%.6f %s %.10f\n" "$A" "$E" "$V" > "runs/${tag}.dat"

