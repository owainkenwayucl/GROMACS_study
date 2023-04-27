#!/usr/bin/env gnuplot

set datafile commentschars "#@&"

set term png
set output "owain-struct_f-mdp.png"

set title "GROMACS on Myriad MSD comparison - Graphene in water with 'problem' MDP file."
set xlabel "Time (ps)"
set ylabel "MSD (nm\\S2\\N)"

plot "owain-struct_f-mdp_2018.dat" title "GROMACS 2018.2" w lines, "owain-struct_f-mdp_2021.dat" title "GROMACS 2021.5" w lines
