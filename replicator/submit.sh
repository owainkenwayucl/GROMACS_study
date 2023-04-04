#!/bin/bash -l

#$ -l h_rt=48:00:00
#$ -l mem=4G
#$ -pe mpi 36
#$ -cwd
#$ -N GROMACS_replication_study

#$ -t 2018-2023
set -e

export _GRO_MAJOR_VERSION=${SGE_TASK_ID}

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

_DIR_NAME="GROMACS-${_GRO_MAJOR_VERSION}-${JOB_ID}"

mkdir -p ${_DIR_NAME}
cd ${_DIR_NAME}

git clone https://github.com/owainkenwayucl/GROMACS_study.git

cp GROMACS_study/replicator/build.sh .
rm -rf GROMACS_study

GROMACS_VER=${_GRO_MAJOR_VERSION} ./build.sh

gmx_mpi grompp -f production.mdp -c min1.gro -p GRA_master.top -o production.tpr 

mpirun -np ${NSLOTS} gmx_mpi mdrun -deffnm production -s production.tpr

echo 0 | gmx_mpi msd -f production.trr -s production.gro -o production_${_GRO_MAJOR_VERSION}.xvg
cat production_${_GRO_MAJOR_VERSION}.xvg | sed '/^@/d' | sed '/^#/d' > production_${_GRO_MAJOR_VERSION}.dat
