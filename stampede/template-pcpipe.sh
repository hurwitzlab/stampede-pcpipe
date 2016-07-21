#!/bin/bash

#
# Set up "bin"
#
BIN="bin.tgz"

if [[ -e $BIN ]]; then
  tar zxvf $BIN
  export PATH=./bin:$PATH
else
  echo "Cannot find \"$BIN\""
  exit 1
fi

chmod +x pcpipe/*.{sh,pl}

RUN_SCRIPT="./pcpipe/run-pcpipe.sh"

if [[ ! -x $RUN_SCRIPT ]]; then
  echo "Cannot execute RUN_SCRIPT \"$RUN_SCRIPT\""
  echo "Contents:"
  find . | xargs ls -lh
  exit 1
fi

echo "Started $(date)"
$RUN_SCRIPT -a $SCRATCH/simap/features -b $SCRATCH/simap/blast/simap -d ${FASTA_DIR} -c ${CLUSTER_FILE} -s ${MIN_CLUSTER_SIZE:-2}
echo "Ended $(date)"

if [[ -d bin ]]; then
  rm -rf bin
fi
