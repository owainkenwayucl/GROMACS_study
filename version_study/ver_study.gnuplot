#!/usr/bin/env gnuplot

set term png
set output "ver_study.png"

set title "GROMACS on Myriad MSD comparison"
set xlabel "Time (ps)"
set ylabel "MSD (nm\\S2\\N)"

plot "ver_study_myriad_2018.ssv" title "GROMACS 2018.2" w lines, "ver_study_myriad_2019.ssv" title "GROMACS 2019.6" w lines, "ver_study_myriad_2020.ssv" title "GROMACS 2020.6" w lines, "ver_study_myriad_2021.ssv" title "GROMACS 2021.5" w lines, "ver_study_myriad_2022.ssv" title "GROMACS 2022.5" w lines, "ver_study_myriad_2023.ssv" title "GROMACS 2023" w lines
