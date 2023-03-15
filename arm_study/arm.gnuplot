#!/usr/bin/env gnuplot

set datafile commentschars "#@&"

set term png
set output "arm.png"

set title "GROMACS on Arm MSD comparison"
set xlabel "Time (ps)"
set ylabel "MSD (nm\\S2\\N)"

plot "graviton_2018.2.ssv" title "GROMACS 2018.2" w lines, "graviton_2021.5.ssv" title "GROMACS 2021.5" w lines, "graviton_2023.ssv" title "GROMACS 2023" w lines
