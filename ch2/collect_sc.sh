grep "!    total energy" runs/pt_sc_A*.out \
  | sed -E 's/.*_A([0-9.]+)\.out:.*= *([-0-9.]+) Ry/\1 \2/' \
  | awk '{a[$1]=$2} END{for(k in a) printf "%s %s\n", k, a[k]}' \
  | sort -n > E_vs_A_sc.dat

