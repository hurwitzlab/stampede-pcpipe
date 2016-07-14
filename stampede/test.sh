#!/bin/bash

#SBATCH -J pcpipe
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -p normal
#SBATCH -o pcpipe-%j.out
#SBATCH -t 02:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=kyclark@email.arizona.edu

echo Started PCPipe at $(date)

module load blast 

BIN="$( readlink -f -- "${0%/*}" )"
ORFS=$WORK/data/pcpipe/test/orfs
CLUSTER=$WORK/data/pcpipe/test/TOV_43_all_contigs_predicted_proteins.faa
OUT_DIR=$HOME/pcpipe
BLAST=${blast_db:-$WORK/data/simap/blast/simap}
FEATURES_DB=${features_db:-$WORK/data/simap/features}
NCPU=${NCPU:-256}
MIN_CLUSTER_SIZE=${MIN_CLUSTER_SIZE:-2}

if [[ -s bin.tgz ]]; then
  tar -xvf bin.tgz
  export PATH=$PATH:"$PWD/bin"
else
  echo Cannot find bin.tgz
fi

$WORK/stampede-pcpipe/stampede/pcpipe/scripts/run-pcpipe.sh \
  -d $ORFS \
  -c $CLUSTER \
  -o $OUT_DIR \
  -b $BLAST \
  -a $FEATURES_DB \
  -n $NCPU \
  -s $MIN_CLUSTER_SIZE

# Now, delete the bin/ directory
rm -rf bin

echo Finished PCPipe at $(date)
