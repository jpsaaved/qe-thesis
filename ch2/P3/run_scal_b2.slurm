
#!/bin/bash
#SBATCH --job-name=scal_b2_scan
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=01:30:00
#SBATCH --array=0-30
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail
export OMP_NUM_THREADS=1
module purge || true
module load qe
# If your cluster doesn't use modules, ensure pw.x is on PATH:
# export PATH=/apps/pkg/qe/7.3/intel/bin:$PATH

mkdir -p runs tmp logs pseudos

# --- point pseudo_dir to PSLibrary PBE UPFs (copy or symlink them once) ---
# ln -s /path/to/pslibrary.1.0.0/PBE/PSEUDOPOTENTIALS/* pseudos_PBE/ 2>/dev/null || true

# --- load list of a-values ---
Avals=($(grep -v '^#' a_list.txt | tr -d '\r'))
LINE=$((SLURM_ARRAY_TASK_ID + 1))
A=${Avals[$SLURM_ARRAY_TASK_ID]}

tag=$(printf "scal_b2_a%.3f" "$A")
in="runs/${tag}.in"
out="runs/${tag}.out"

# make numeric input from template
awk -v AAAA="$A" '{gsub(/AAAA/,AAAA); print}' ScAl_B2.in.tpl > "$in"

# quick sanity checks
command -v pw.x >/dev/null || { echo "pw.x not found in PATH"; exit 127; }
grep -q "ATOMIC_SPECIES" "$in" || { echo "bad input"; exit 2; }

# run
srun --mpi=pmix --cpu-bind=cores pw.x -in "$in" > "$out"

# robust energy extraction (handles spacing / with/without "!")
E=$(tac "$out" | grep -m1 -E '^[[:space:]]*!?[[:space:]]*total[[:space:]]+energy[[:space:]]*=' | awk '{print $(NF-1)}' || true)
[[ -z "$E" ]] && { echo "WARN: energy not found in $out"; E="NaN"; }

# volume per f.u. (simple cubic): V = a^3
V=$(python - <<PY
import math; a=$A
print(f"{a**3:.10f}")
PY
)

printf "%.6f %s %.10f\n" "$A" "$E" "$V" > "runs/${tag}.dat"
echo "done: a=$A E=$E Ry V=$V Å^3"

