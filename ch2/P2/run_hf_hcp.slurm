#!/bin/bash
#SBATCH --job-name=hf_hcp_scan_p2
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --time=01:00:00
#SBATCH --array=0-29                   # lattice points
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail
module purge
module load qe                         # quantum-espresso module on your cluster
export OMP_NUM_THREADS=1

mkdir -p runs tmp logs

# ---------- Problem-2 settings ----------
r=1.58
Avals=($(cat lattice_list.txt))
A=${Avals[$SLURM_ARRAY_TASK_ID]}

# compute a*sqrt(3) and c=r*a numerically
read Ay C < <(python - <<PY
import math
A = $A
r = $r
print(f"{A*math.sqrt(3.0):.10f} {r*A:.10f}")
PY
)

tag="hf_hcp_a${A}"
infile="runs/${tag}.in"
outfile="runs/${tag}.out"

# ---------- generate numeric input ----------
# template must contain placeholders AAX_Y, AAY, CCX
awk -v AAX_Y="$A" -v AAY="$Ay" -v CCX="$C" '
  { gsub(/AAX_Y/,AAX_Y); gsub(/AAY/,AAY); gsub(/CCX/,CCX); print }
' hf_hcp.in > "$infile"

# ---------- run QE ----------
srun --mpi=pmix pw.x -nk 4 -in "$infile" > "$outfile"

# --- extract energy and volume robustly ---
E=$(tac "$outfile" \
    | grep -m1 -E '^[[:space:]]*!?[[:space:]]*total[[:space:]]+energy[[:space:]]*=' \
    | awk '{print $(NF-1)}' || true)

if [[ -z "$E" ]]; then
  echo "WARN: energy not found in $outfile; marking NaN" >&2
  E="NaN"
fi

V=$(python - <<PY
import math
A=$A; r=$r
print(f"{(math.sqrt(3.0)/4.0)*A**3*r:.10f}")
PY
)
echo "$A $E $V" > "runs/${tag}.dat"

echo "✅ Done: a=$A Å  a√3=$Ay Å  c=$C Å  E=$E Ry  V=$V Å³/atom"

