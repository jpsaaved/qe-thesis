&control
    calculation   = 'scf',
    prefix        = 'PREFIX',
    pseudo_dir    = '/users/jsaaved1/research/pslibrary.1.0.0/pbe/PSEUDOPOTENTIALS',
    outdir        = './tmp',
    verbosity     = 'high',
/
&system
    ibrav         = 3,
    A             = AAAA,
    nat           = 1,
    ntyp          = 1,
    ecutwfc       = 45.0,
    ecutrho       = 360.0,
    occupations   = 'smearing',
    smearing      = 'mv',
    degauss       = 0.01,
    nspin         = 1,     ! non-magnetic
/
&electrons
    conv_thr      = 1.0d-8,
    mixing_beta   = 0.7,
/
ATOMIC_SPECIES
 Fe 55.845 Fe.pbe-spn-kjpaw_psl.1.0.0.UPF

ATOMIC_POSITIONS crystal
 Fe 0.00 0.00 0.00

K_POINTS automatic
 12 12 12 1 1 1

