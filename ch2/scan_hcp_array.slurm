#!/bin/bash
#SBATCH --job-name=pt_hcp_scan
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --time=00:30:00
#SBATCH --array=1-26                    
#SBATCH --output=logs/%x_%A_%a.out

module load qe                            # adjust to your cluster
export OMP_NUM_THREADS=1
mkdir -p runs logs pseudo scratch

# ----- Scan settings (MATLAB-style start:step:end) -----
START=2.50
STEP=0.10
END=5.00

CA=1.633                                  # c/a (try 1.58 and 1.68 too if curious)

# Pick A for this array task; exit quietly if index > list length
A=$(seq -f "%.2f" ${START} ${STEP} ${END} | sed -n "${SLURM_ARRAY_TASK_ID}p")
if [ -z "$A" ]; then
  echo "No A for task ${SLURM_ARRAY_TASK_ID}; skipping."
  exit 0
fi

# Compute C = (c/a)*A with consistent decimals
C=$(awk -v a="$A" -v ca="$CA" 'BEGIN{printf("%.6f", a*ca)}')

# (Optional) skip obviously too-compressed cells that often blow up SCF
# awk "BEGIN{exit !($A >= 2.70)}" || { echo "Skipping A=$A (too small)"; exit 0; }

# ---------- Build input (ibrav=4 = hexagonal primitive), nat=2 ----------
cat > runs/pt_hcp_A${A}.in <<EOF
&control
  calculation='scf', prefix='pt_hcp_A${A}',
  pseudo_dir='./pseudo', outdir='./scratch'
/
&system
  ibrav=4, A=${A}, C=${C},
  nat=2, ntyp=1,
  ecutwfc=60, ecutrho=480,
  occupations='smearing', smearing='mp', degauss=0.03
/
&electrons
  conv_thr=1.0d-6, mixing_beta=0.4, mixing_ndim=10, electron_maxstep=200
/
ATOMIC_SPECIES
  Pt 195.084 pt_pbesol_v1.4.uspp.F.UPF
ATOMIC_POSITIONS crystal
  Pt 0.000000 0.000000 0.000000
  Pt 0.666667 0.333333 0.500000
K_POINTS automatic
  16 16 12  1 1 1
EOF

echo "Running hcp Pt at A=${A} Å, C=${C} Å  (NTASKS=${SLURM_NTASKS})"
srun -n ${SLURM_NTASKS} pw.x -in runs/pt_hcp_A${A}.in > runs/pt_hcp_A${A}.out

