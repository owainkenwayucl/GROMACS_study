#!/usr/bin/env gnuplot
#myriad_2018.2_msd_by_2023.ssv  ver_study_myriad_2018.ssv

set datafile commentschars "#@&"

set term png
set output "msd.png"

set title "GROMACS 2018.2 vs 2023 MSD comparison"
set xlabel "Time (ps)"
set ylabel "MSD (nm\\S2\\N)"

plot "ver_study_myriad_2018.ssv" title "GROMACS 2018.2 with 2018.2 MSD" w lines, "myriad_2018.2_msd_by_2023.ssv" title "GROMACS 2018.2 with 2023 MSD" w lines
