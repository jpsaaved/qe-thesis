for f in runs/pt_hcp_A*.out; do
  A=$(echo "$f" | sed -E 's/.*_A([0-9.]+)\.out/\1/')
  E=$(grep -E "^! *total energy" "$f" | tail -n 1 | awk '{print $5}')
  printf "%.2f %.10f\n" "$A" "$(awk -v e="$E" 'BEGIN{print e/2.0}')"
done | sort -n > E_vs_A_hcp_peratom.dat

