#!/bin/bash

#
# Run the PCPipe analysis
# Authors: 
#  Bonnie Hurwitz <bhurwitz@email.arizona.edu>
#  Ken Youens-Clark <kyclark@email.arizona.edu>
#

IN_DIR=""
CLUSTER_FILE=""
PROG_NAME=$(basename "$0" '.sh')
OUT_DIR="$PWD/$PROG_NAME"
MIN_CLUSTER_SIZE=2
NUM_CPU=4
SIMAP_BLAST_DB=""
SIMAP_ANNOTATION_DB_DIR=""
OVERWRITE=0

function HELP() {
  printf "Usage:\n  %s -d FASTA_DIR -c CLUSTER_FILE\n\n" \
    $(basename $0)
  
  echo "Required arguments:"
  echo " -d FASTA_DIR (sequence files to screen)"
  echo " -c CLUSTER_FILE (existing cluster file to screen against)"
  echo " -a SIMAP_ANNOTATION_DB_DIR"
  echo " -b SIMAP_BLAST_DB"
  echo
  echo "Options: "
  echo " -n NUM_CPU ($NUM_CPU)"
  echo " -o OUT_DIR ($OUT_DIR)"
  echo " -s MIN_CLUSTER_SIZE ($MIN_CLUSTER_SIZE)"
  echo " -x OVERWRITE ($OVERWRITE)"
  exit
}

function lc() {
    wc -l "$1" | cut -d ' ' -f 1
}

if [[ $# == 0 ]]; then
  HELP
fi

while getopts :a:b:c:d:hn:o:s:x OPT; do
  case $OPT in
    a)
      SIMAP_ANNOTATION_DB_DIR="$OPTARG"
      ;;
    b)
      SIMAP_BLAST_DB="$OPTARG"
      ;;
    c)
      CLUSTER_FILE="$OPTARG"
      ;;
    d)
      IN_DIR="$OPTARG"
      ;;
    h)
      HELP
      ;;
    n)
      NUM_CPU="$OPTARG"
      ;;
    o)
      OUT_DIR="$OPTARG"
      ;;
    s)
      MIN_CLUSTER_SIZE="$OPTARG"
      ;;
    x)
      OVERWRITE=1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    \?)
      echo "Invalid option: -${OPTARG:-""}"
      exit 1
  esac
done

set -u

DIV='# --------------------------------------------------'
echo "STARTED $(date)"
echo "$DIV"
echo "IN_DIR=\"$IN_DIR\""
echo "CLUSTER_FILE=\"$CLUSTER_FILE\""
echo "OUT_DIR=\"$OUT_DIR\""
echo "MIN_CLUSTER_SIZE=\"$MIN_CLUSTER_SIZE\""
echo "NUM_CPU=\"$NUM_CPU\""
echo "SIMAP_BLAST_DB=\"$SIMAP_BLAST_DB\""
echo "SIMAP_ANNOTATION_DB_DIR=\"$SIMAP_ANNOTATION_DB_DIR\""
echo "OVERWRITE=\"$OVERWRITE\""
echo "$DIV"

#
# Check args
#
if [[ ${#IN_DIR} -lt 1 ]]; then
  echo "Missing IN_DIR argument"
  exit 1
fi

if [[ ${#SIMAP_BLAST_DB} -lt 1 ]]; then
  echo "Missing SIMAP_BLAST_DB argument"
  exit 1
fi

if [[ ${#SIMAP_ANNOTATION_DB_DIR} -lt 1 ]]; then
  echo "Missing SIMAP_ANNOTATION_DB_DIR argument"
  exit 1
fi

if [[ ! -d "$IN_DIR" ]]; then
  echo "IN_DIR \"$IN_DIR\" does not exist."
  exit 1
fi

if [[ ! -s "$CLUSTER_FILE" ]]; then
  echo "Bad CLUSTER_FILE \"$CLUSTER_FILE\""
  exit 1
fi

if [[ $MIN_CLUSTER_SIZE -lt 2 ]]; then
  echo "MIN_CLUSTER_SIZE cannot be less than 2"
  exit 1
fi

if [[ ! -d "$OUT_DIR" ]]; then
  mkdir -p "$OUT_DIR"
fi

#
# Put all the incoming sequences into one file
#
SEQUENCES_FILE="$OUT_DIR/compiled_sequences.fa"

if [[ -e "$SEQUENCES_FILE" ]]; then
  rm "$SEQUENCES_FILE"
fi

FILES_LIST="$OUT_DIR/files_list"
find "$IN_DIR" -maxdepth 1 -mindepth 1 -type f -size +0c > "$FILES_LIST"

NUM_FILES=$(lc "$FILES_LIST")
echo "Found \"$NUM_FILES\" files in \"$IN_DIR\""

if [[ $NUM_FILES -lt 1 ]]; then
  echo "Found no files in \"$IN_DIR\""
  exit
fi

while read FILE; do
  echo "Compiling $FILE"
  cat $FILE >> $SEQUENCES_FILE
done < $FILES_LIST

if [[ ! -s "$SEQUENCES_FILE" ]]; then
  echo "Empty SEQUENCES_FILE \"$SEQUENCES_FILE\""
  exit
fi

#
# Run cd-hit-2d
# It will create a "clstr" file of those that did cluster 
# and the -o "novel" file of those that didn't -- this is
# the file we want to self-cluster with cd-hit
#
CD_HIT_2D_IDEN="0.6"
CD_HIT_2D_COV="0.8"
CD_HIT_2D_OPTS="-g 1 -n 4 -d 0 -T 24 -M 45000"
CD_HIT_2D_OUT_DIR="$OUT_DIR/cdhit-2d-outdir"
CD_HIT_2D_NOVEL="$CD_HIT_2D_OUT_DIR/novel.fa"

if [[ ! -d "$CD_HIT_2D_OUT_DIR" ]]; then
  mkdir -p "$CD_HIT_2D_OUT_DIR"
fi

if [[ -s "$CD_HIT_2D_NOVEL" ]] && [[ $OVERWRITE -eq 0 ]]; then
  echo "CD_HIT_2D_NOVEL \"$CD_HIT_2D_NOVEL\" exists already."
else
  echo "Running cd-hit-2d"
  cd-hit-2d \
    -i  $CLUSTER_FILE \
    -i2 $SEQUENCES_FILE \
    -o  $CD_HIT_2D_NOVEL \
    -c  $CD_HIT_2D_IDEN \
    -aS $CD_HIT_2D_COV \
    $CD_HIT_2D_OPTS
fi

if [[ ! -s "$CD_HIT_2D_NOVEL" ]]; then
  echo "All sequences clustered to $CLUSTER_FILE.  Exiting."
  exit
fi

#
# Run cd-hit on the "novel" sequences
#
CD_HIT_IDEN="0.6"
CD_HIT_COV="0.8"
CD_HIT_OPTS="-g 1 -n 4 -d 0 -T 24 -M 45000"
CD_HIT_OUT_DIR="$OUT_DIR/cdhit-outdir"
CD_HIT_OUT_FILE="$CD_HIT_OUT_DIR/cdhit60"

if [[ ! -d "$CD_HIT_OUT_DIR" ]]; then
  mkdir -p "$CD_HIT_OUT_DIR"
fi

if [[ -s "$CD_HIT_OUT_FILE" ]] && [[ $OVERWRITE -eq 0 ]]; then
  echo "CD_HIT_OUT_FILE \"$CD_HIT_OUT_FILE\" exists already."
else
  echo "Running cd-hit"
  cd-hit \
    -i  $CD_HIT_2D_NOVEL \
    -o  $CD_HIT_OUT_FILE \
    -c  $CD_HIT_IDEN \
    -aS $CD_HIT_COV \
    $CD_HIT_OPTS
fi

#
# Create a FASTA file of the representative sequences from 
# clusters having more than 20 constituents
#
CD_HIT_CLUSTER_FILE="$CD_HIT_OUT_FILE.clstr"

if [[ ! -s "$CD_HIT_CLUSTER_FILE" ]]; then
  echo "CD_HIT_CLUSTER_FILE \"$CD_HIT_CLUSTER_FILE\" is empty?"
  echo "No cluster file from cd-hit."
  exit
fi

NOVEL_FA="$OUT_DIR/novel.fa"
fa_from_clusters.pl \
  --cluster_file  $CD_HIT_CLUSTER_FILE \
  --sequence_file $SEQUENCES_FILE \
  -n              $MIN_CLUSTER_SIZE \
  -o              $NOVEL_FA

echo "New cluster file \"$NOVEL_FA\""

BLAST_OUT="$OUT_DIR/blast.out"
echo "BLASTing to \"$SIMAP_BLAST_DB\""

if [[ -s "$BLAST_OUT" ]]; then
  echo "$BLAST_OUT already exists"
else 
  blastp \
  -query $NOVEL_FA \
  -out $BLAST_OUT \
  -outfmt 6 \
  -db $SIMAP_BLAST_DB \
  -num_alignments 10 \
  -num_descriptions 10 \
  -evalue 1 \
  -num_threads $NUM_CPU
fi

if [[ ! -s "$BLAST_OUT" ]]; then
  echo "Nothing returned from BLAST, exiting."
  exit
fi

echo "BLAST_OUT \"$BLAST_OUT\""

ANNOT_FILE="$OUT_DIR/simap-annotations.tab"

annotate-blast.pl \
  --blast  $BLAST_OUT \
  --db_dir $SIMAP_ANNOTATION_DB_DIR \
  --out    $ANNOT_FILE

echo "Finished PCPipe, see annotation file \"$ANNOT_FILE\""
echo "Ended $(date)"
