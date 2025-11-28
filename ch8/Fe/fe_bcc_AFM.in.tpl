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
    nat           = 2,
    ntyp          = 2,
    ecutwfc       = 45.0,
    ecutrho       = 360.0,

    occupations   = 'smearing',
    smearing      = 'mv',
    degauss       = 0.01,

    nspin         = 2,
    starting_magnetization(1) = 0.6,   ! Fe1 up
    starting_magnetization(2) = -0.6,  ! Fe2 down
    ! no tot_magnetization here
/
&electrons
    conv_thr      = 1.0d-8,
    mixing_beta   = 0.5,
/
ATOMIC_SPECIES
 Fe1 55.845 Fe.pbe-spn-kjpaw_psl.1.0.0.UPF
 Fe2 55.845 Fe.pbe-spn-kjpaw_psl.1.0.0.UPF

ATOMIC_POSITIONS crystal
 Fe1 0.00 0.00 0.00
 Fe2 0.50 0.50 0.50

K_POINTS automatic
 12 12 12 1 1 1

