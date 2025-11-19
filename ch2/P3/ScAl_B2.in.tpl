&control
  calculation = 'scf',
  prefix      = 'ScAl_B2',
  outdir      = './tmp',
  pseudo_dir  = '/users/jsaaved1/research/pslibrary.1.0.0/pbe/PSEUDOPOTENTIALS' 
/
&system
  ibrav = 1,  A = AAAA,           ! <-- substitute AAAA with the a value (Å)
  nat = 2, ntyp = 2,
  input_dft = 'PBE',
  ecutwfc = 70,  ecutrho = 280,   ! good PBE-USPP starting point; converge if needed
  occupations = 'smearing', smearing='mp', degauss=0.02
/
&electrons
  conv_thr = 1.0d-8,  mixing_beta = 0.3, electron_maxstep = 200
/
ATOMIC_SPECIES
  Sc 44.9559 Sc.pbe-spn-kjpaw_psl.1.0.0.UPF
  Al 26.9815 Al.pbe-n-kjpaw_psl.1.0.0.UPF
ATOMIC_POSITIONS crystal
  Sc 0.000000 0.000000 0.000000
  Al 0.500000 0.500000 0.500000
K_POINTS automatic
  18 18 18  0 0 0

