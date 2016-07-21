#!/bin/bash

#SBATCH -A iPlant-Collabs
#SBATCH -J pcpipe
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -p development
#SBATCH -t 02:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=kyclark@email.arizona.edu

module load blast
module load perl/5.16.2

tar zxvf bin.tgz

PATH=./bin:$PATH

./pcpipe/run-pcpipe.sh \
  -d $SCRATCH/pcpipe/orfs \
  -c $SCRATCH/pcpipe/test.fa \
  -a $SCRATCH/simap/features \
  -b $SCRATCH/simap/blast/simap \
  -o $SCRATCH/pcpipe-out \
  -s 2 \
  -n 4

rm -rf bin
