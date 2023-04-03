#!/usr/bin/env bash
# based on https://www.erastova.xyz/teaching/practical-simulations-for-molecules-and-materials/material-simulations/graphene-simulation-set-up/
# Owain Kenway

set -e

source /etc/profile.d/modules.sh

module load personal-modules
module load spack-test

export _GRO_MAJOR_VERSION=${GROMACS_VERSION:-2018.2}
export _GRO_COMMAND="mpirun -np 1 gmx_mpi"
export _Z_SCALE=10
export _X_SCALE=15
export _Y_SCALE=10

module load spack-test

_GRO_MODULE=$(module avail -t gromacs-${_GRO_MAJOR_VERSION} 2>&1 | tail -n 1)
if [ "${_GRO_MAJOR_VERSION}" \> "2018" ]
then
  _OMP_VERSION=4.1.5
else
  _OMP_VERSION=3.1.6
fi

_OMP_MODULE=$(module avail -t openmpi-${_OMP_VERSION} 2>&1 | tail -n 1)

echo "Selected GROMACS module: ${_GRO_MODULE}"
echo "Selected OpenMPI module: ${_OMP_MODULE}"

module load ${_OMP_MODULE}
module load ${_GRO_MODULE}

# Prep force field
echo "Prepping Force Field"

tar -xvf ${HOME}/tar/charmm36-jul2022.ff.tgz
mv charmm36-jul2022.ff charmm36.ff

cat << EOF > charmm36.ff/graphene.n2t
C    CG2R61   0.00      12.011  1    C 0.142
C    CG2R61   0.00      12.011  2    C 0.142   C 0.142
C    CG2R61   0.00      12.011  3    C 0.142   C 0.142   C 0.142
EOF

# Write a unit cell
echo "Writing unit cell"

cat << EOF > GRA_unit_cell.gro
GRA: 1 1 Rcc=1.420 Rhole=0.000 Center: Ring
4
    1GRA   C1      1   0.061   0.071   0.000
    1GRA   C2      2   0.184   0.142   0.000
    1GRA   C3      3   0.184   0.284   0.000
    1GRA   C4      4   0.061   0.355   0.000
    0.245951    0.426000    0.284000
EOF

# Create the sheet by replication
echo "Create sheet by replication"
${_GRO_COMMAND} genconf -f GRA_unit_cell.gro -o GRA_sheet.gro -nbox ${_X_SCALE} ${_Y_SCALE} 1

# Generate topology file
echo "Generating topology file"
${_GRO_COMMAND} x2top -f GRA_sheet.gro -o GRA.top -name GRA -nexcl 3 -ff charmm36 -kb 255224 -kt 334.72 -kp 12.9704 -alldih

# Cut up the GRA.top file to generate GRA.itp
echo "Cutting up GRA.top to generate GRA.itp"
csplit GRA.top "/\[ moleculetype \]/"
cp xx01 gra.tmp
csplit gra.tmp "/\[ system \]/"
cp xx00 GRA.itp
rm xx*
rm gra.tmp

# Set up master top file
echo "Setting up master topology file"
cat << EOF > GRA_master.top
#include "./charmm36.ff/forcefield.itp"
#include "./GRA.itp"
#include "./charmm36.ff/tip3p.itp"

[ system ]
; Name
GRA in water

[ molecules ]
; Compound #mols
GRA        1
SOL        50
EOF

# Scale Z direction _Z_SCALE
echo "Scaling Z dimension by ${_Z_SCALE}x"
${_GRO_COMMAND} editconf -f GRA_sheet.gro -c -scale 1 1 ${_Z_SCALE} -o GRA_sheet_Z.gro

# Solvate the system. This will add water into the vacuum.
echo "Solvating the system"
${_GRO_COMMAND} solvate -cp GRA_sheet_Z.gro -o GRA_final.gro -p GRA_master.top

# Generate minimisation mdp
# This one is from a GROMACS tutorial: http://www.mdtutorials.com/gmx/lysozyme/Files/minim.mdp
echo "Generating minimisation mdp"
cat << EOF > min.mdp
; minim.mdp - used as input into grompp to generate em.tpr
; Parameters describing what to do, when to stop and what to save
integrator  = steep         ; Algorithm (steep = steepest descent minimization)
emtol       = 1000.0        ; Stop minimization when the maximum force < 1000.0 kJ/mol/nm
emstep      = 0.01          ; Minimization step size
nsteps      = 50000         ; Maximum number of (minimization) steps to perform

; Parameters describing how to find the neighbors of each atom and how to calculate the interactions
nstlist         = 1         ; Frequency to update the neighbor list and long range forces
cutoff-scheme   = Verlet    ; Buffered neighbor searching
ns_type         = grid      ; Method to determine neighbor list (simple, grid)
coulombtype     = PME       ; Treatment of long range electrostatic interactions
rcoulomb        = 1.0       ; Short-range electrostatic cut-off
rvdw            = 1.0       ; Short-range Van der Waals cut-off
pbc             = xyz       ; Periodic Boundary Conditions in all 3 dimensions
periodic_molecules = yes    ; a la Graphene tutorial
EOF

# Generate minimisation tpr
echo "Generating minimisation tpr"
${_GRO_COMMAND} grompp -f min.mdp -c GRA_final.gro -p GRA_master.top -o min1.tpr 

# Do the minimisation
echo "Doing minimisation"
${_GRO_COMMAND} mdrun -v -deffnm min1

# Generate run mdp
# This one is from a GROMACS tutorial: http://www.mdtutorials.com/gmx/lysozyme/Files/nvt.mdp
echo "Generating run mdp"
cat << EOF > production.mdp
define                  = -DPOSRES  ; position restrain the protein
; Run parameters
integrator              = md        ; leap-frog integrator
nsteps                  = 50000     ; 2 * 50000 = 100 ps
dt                      = 0.002     ; 2 fs
; Output control
nstxout                 = 500       ; save coordinates every 1.0 ps
nstvout                 = 500       ; save velocities every 1.0 ps
nstenergy               = 500       ; save energies every 1.0 ps
nstlog                  = 500       ; update log file every 1.0 ps
; Bond parameters
continuation            = no        ; first dynamics run
constraint_algorithm    = lincs     ; holonomic constraints 
constraints             = h-bonds   ; bonds involving H are constrained
lincs_iter              = 1         ; accuracy of LINCS
lincs_order             = 4         ; also related to accuracy
; Nonbonded settings 
cutoff-scheme           = Verlet    ; Buffered neighbor searching
ns_type                 = grid      ; search neighboring grid cells
nstlist                 = 10        ; 20 fs, largely irrelevant with Verlet
rcoulomb                = 1.0       ; short-range electrostatic cutoff (in nm)
rvdw                    = 1.0       ; short-range van der Waals cutoff (in nm)
DispCorr                = EnerPres  ; account for cut-off vdW scheme
; Electrostatics
coulombtype             = PME       ; Particle Mesh Ewald for long-range electrostatics
pme_order               = 4         ; cubic interpolation
fourierspacing          = 0.16      ; grid spacing for FFT
; Temperature coupling is on
tcoupl                  = V-rescale             ; modified Berendsen thermostat
tc-grps                 = SOL     GRA
tau_t                   = 0.1     0.1           ; time constant, in ps
ref_t                   = 300     300           ; reference temperature, one for each group, in K
; Pressure coupling is off
pcoupl                  = no        ; no pressure coupling in NVT
; Periodic boundary conditions
pbc                     = xyz       ; 3-D PBC
; Velocity generation
gen_vel                 = yes       ; assign velocities from Maxwell distribution
gen_temp                = 300       ; temperature for Maxwell distribution
gen_seed                = -1        ; generate a random seed
periodic_molecules = yes    ; a la Graphene tutorial
EOF


