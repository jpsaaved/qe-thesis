#!/bin/bash
#SBATCH --job-name=pt_sc_scan
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --time=00:30:00
#SBATCH --array=1-61                 # enough for 2.00:0.05:5.00 (61 values)
#SBATCH --output=logs/%x_%A_%a.out

module load qe                       # adjust to your cluster's QE module name
export OMP_NUM_THREADS=1
mkdir -p runs logs pseudo scratch

# ---- Choose your scan range (MATLAB style start:step:end) ----
START=2.00
STEP=0.05
END=5.00

# Pick A for this array task (guard if the index is out of range)
A=$(seq -f "%.2f" ${START} ${STEP} ${END} | sed -n "${SLURM_ARRAY_TASK_ID}p")
if [ -z "$A" ]; then
  echo "No A for task ${SLURM_ARRAY_TASK_ID}; skipping."
  exit 0
fi

# Optional: skip obviously unphysical tiny A for sc Pt (uncomment if needed)
# awk "BEGIN{exit !($A >= 2.70)}" || { echo "Skipping A=$A (too small)"; exit 0; }

# Build the SC input (ibrav=1 = simple cubic), nat=1, ntyp=1
cat > runs/pt_sc_A${A}.in <<EOF
&control
  calculation='scf', prefix='pt_sc_A${A}',
  pseudo_dir='./pseudo', outdir='./scratch'
/
&system
  ibrav=1, A=${A},
  nat=1, ntyp=1,
  ecutwfc=60, ecutrho=480,
  occupations='smearing', smearing='mp', degauss=0.03
/
&electrons
  conv_thr=1.0d-6, mixing_beta=0.4, mixing_ndim=10, electron_maxstep=200
/
ATOMIC_SPECIES
  Pt 195.084 pt_pbesol_v1.4.uspp.F.UPF
ATOMIC_POSITIONS crystal
  Pt 0 0 0
K_POINTS automatic
  16 16 16  1 1 1
EOF

echo "Running sc Pt at A=${A} Å  (NTASKS=${SLURM_NTASKS})"
srun -n ${SLURM_NTASKS} pw.x -in runs/pt_sc_A${A}.in > runs/pt_sc_A${A}.out

