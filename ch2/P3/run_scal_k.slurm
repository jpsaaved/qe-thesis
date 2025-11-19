#!/bin/bash
#SBATCH --job-name=scal_k_scan
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=01:30:00
#SBATCH --array=0-23
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

# --- load list of k-points --- #
mapfile -t Kvals < <(grep -v '^\s*#' k_list.txt | tr -d '\r' | xargs)
N=${#Kvals[@]}
if (( SLURM_ARRAY_TASK_ID >= N )); then
  echo "Array index $SLURM_ARRAY_TASK_ID out of range for k_list.txt (N=$N)"; exit 2
fi
K=${Kvals[$SLURM_ARRAY_TASK_ID]}

tag=$(printf "scal_b2_kp%02d" "$K")
in="runs/${tag}.in"
out="runs/${tag}.out"

# make numeric input from template
awk -v KP="$K" '{gsub(/KP/,KP); print}' ScAl_scan_k.tpl > "$in"

# quick sanity checks
command -v pw.x >/dev/null || { echo "pw.x not found in PATH"; exit 127; }
grep -q "ATOMIC_SPECIES" "$in" || { echo "bad input"; exit 2; }

# run
srun pw.x -in "$in" > "$out" 2>&1

# ---- robust final energy: take last '! total energy' (F) and add back TS ----
read F_RY TS_RY E_RY <<<"$(
python - <<'PY' "$out"
import re, sys, math
F=None; TS=None
with open(sys.argv[1],'r',errors='ignore') as f:
    for line in f:
        s=line.lstrip()
        if s.startswith('!') and 'total energy' in s:
            m=re.search(r'=\s*([-\d.+Ee]+)\s*Ry', s)
            if m: F=float(m.group(1))      # free energy (last occurrence)
        elif 'smearing contrib' in line:
            m=re.search(r'=\s*([-\d.+Ee]+)\s*Ry', line)
            if m: TS = -float(m.group(1))  # store +TS
E = (F+TS) if (F is not None and TS is not None) else float('nan')
fmt = lambda x: ('NaN' if x is None or (isinstance(x,float) and math.isnan(x)) else f"{x:.12f}")
print(fmt(F), fmt(TS), fmt(E))
PY
)"

# ---- volume for simple-cubic conventional cell: V = a^3 (a fixed above) ----
V=$(python - <<PY
a=$A
print(f"{a**3:.10f}")
PY
)

# ---- write one row:  KP   E(Ry)   V(Å^3)  (you can add F,TS if you like) ----
printf "%d %s %.10f\n" "$K" "$E_RY" "$V" > "runs/${tag}.dat"
echo "done: KP=$K   E_int=$E_RY Ry   V=$V Å^3  -> runs/${tag}.dat"

# === aggregate later ===
# ls runs/scal_b2_kp*.dat | sort -V | xargs cat > E_vs_k_ScAl_B2.dat
