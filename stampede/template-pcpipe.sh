#!/bin/bash

#
# Set up "bin"
#
if [[ -e bin.tgz ]]; then
  tar zxvf bin.tgz
  PATH=./bin:$PATH
fi

ARGS="-a $SCRATCH/simap/features -b $SCRATCH/simap/blast/simap"

if [[ -n $FASTA_DIR ]]; then
  ARGS="$ARGS -d $FASTA_DIR"
fi

if [[ -n $CLUSTER_FILE ]]; then
  ARGS="$ARGS -c $CLUSTER_FILE"
fi

if [[ -n $MIN_CLUSTER_SIZE ]]; then
  ARGS="$ARGS -s $MIN_CLUSTER_SIZE"
fi

run-pcpipe.sh $ARGS
