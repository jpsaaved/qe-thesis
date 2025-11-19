#!/bin/bash
outfile=E_vs_A_fcc.dat
echo "# a(Å)   Energy(Ry)" > $outfile

for f in runs/pt_fcc_A*.out; do
  A=$(echo $f | sed -E 's/.*_A([0-9.]+)\.out/\1/')
  E=$(grep "!    total energy" "$f" | tail -n 1 | awk '{print $5}')
  echo "$A $E" >> $outfile
done

sort -n $outfile -o $outfile

