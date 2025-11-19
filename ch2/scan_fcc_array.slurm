#!/bin/bash
#SBATCH --job-name=pt_fcc_scan
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --time=00:30:00
#SBATCH --array=1-61
#SBATCH --output=logs/%x_%A_%a.out

module load qe            # your cluster's QE module
export OMP_NUM_THREADS=1
mkdir -p logs runs pseudo scratch

A=$(seq -f "%.2f" 2.00 0.05 5.00 | sed -n "${SLURM_ARRAY_TASK_ID}p")  # sane range

cat > runs/pt_fcc_A${A}.in <<EOF
&control
  calculation='scf', prefix='pt_fcc_A${A}',
  pseudo_dir='./pseudo', outdir='./scratch'
/
&system
  ibrav=2, A=${A}, nat=1, ntyp=1,
  ecutwfc=60, ecutrho=480,
  occupations='smearing', smearing='mp', degauss=0.03
/
&electrons
  conv_thr=1.0d-6, mixing_beta=0.4, mixing_ndim=10
/
ATOMIC_SPECIES
  Pt 195.084 pt_pbesol_v1.4.uspp.F.UPF
ATOMIC_POSITIONS crystal
  Pt 0 0 0
K_POINTS automatic
  16 16 16  1 1 1
EOF

echo "A=${A}  NTASKS=${SLURM_NTASKS}"
srun -n ${SLURM_NTASKS} pw.x -in runs/pt_fcc_A${A}.in > runs/pt_fcc_A${A}.out

