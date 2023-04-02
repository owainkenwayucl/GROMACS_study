#!/usr/bin/env bash

source /etc/profile.d/modules.sh

module load personal-modules
module load spack-test

export _GRO_MAJOR_VERSION=${GROMACS_VERSION:-2018.2}
export _GRO_COMMAND="mpirun -np 1 gmx_mpi"
export _Z_SCALE=50

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
