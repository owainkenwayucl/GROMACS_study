#!/bin/bash -l

#$ -l h_rt=48:00:00
#$ -l mem=4G
#$ -pe mpi 36
#$ -cwd
#$ -N GROMACS_version_study

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

tar xvf ~/tar/GROMACS_FUCKUP.tar.gz

cd GROMACS_FUCKUP

rm -rf 2022-09-13
rm -rf 2022-10-26
rm -rf Graph1.png

cd 2022-09-21

gmx_mpi grompp -f NVT.mdp -c minim_AQUCUM_clean.gro -p AQUCUM_clean.top -o AQUCUM_clean.tpr -maxwarn 2

mpirun -np ${NSLOTS} gmx_mpi mdrun -deffnm AQUCUM_clean_nvt -s AQUCUM_clean.tpr

echo 0 | gmx_mpi msd -f AQUCUM_clean_nvt.xtc -s AQUCUM_clean.tpr -b 2000 -o myriad_${_GRO_MAJOR_VERSION}_cpu.xvg -e 4500

