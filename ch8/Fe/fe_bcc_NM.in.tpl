&control
    calculation   = 'scf',
    prefix        = 'PREFIX',
    pseudo_dir    = '/users/jsaaved1/research/pslibrary.1.0.0/pbe/PSEUDOPOTENTIALS',
    outdir        = 'OUTDIR',
    verbosity     = 'high'
    restart_mode  = 'from_scratch',
/
&system
    ibrav         = 3,
    A             = AAAA,
    nat           = 1,
    ntyp          = 1,
    ecutwfc       = 60.0,
    ecutrho       = 480.0,
    occupations   = 'smearing',
    smearing      = 'mv',
    degauss       = 0.01,

    nspin         = 1,
/
&electrons
    conv_thr      = 1.0d-8,
    mixing_beta   = 0.05,             
    mixing_mode   = 'local-TF',
/
ATOMIC_SPECIES
 Fe 55.845 Fe.pbe-spn-kjpaw_psl.1.0.0.UPF

ATOMIC_POSITIONS crystal
 Fe 0.00 0.00 0.00

K_POINTS automatic
 22 22 22   1 1 1

