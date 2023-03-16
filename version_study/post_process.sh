#!/usr/bin/env bash

source /etc/profile.d/modules.sh

module load personal-modules
module load spack-test
module load vmd/1.9.3/text-only
module load imagemagick-7.0.8-7-gcc-12.2.0-zj7gknr

vmd -dispdev text -eofexit -e render.tcl

for a in *.rgb
do
	convert -strip $a $a.png
	rm $a  
done
