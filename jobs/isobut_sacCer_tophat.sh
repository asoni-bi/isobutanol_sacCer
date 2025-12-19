#!/bin/bash
#SBATCH --job-name=isobut_tophat
#SBATCH --output=logs/slurm/tophat_%x_%j.out
#SBATCH --error=logs/slurm/tophat_%x_%j.err
#SBATCH --time=8:00:00
#SBATCH --mem=10G
#SBATCH --cpus-per-task=2
#SBATCH -p msc_appbio

set -euo pipefail

echo "[$(date)] Job started on host: $(hostname)"
echo "SLURM_JOB_ID = ${SLURM_JOB_ID:-unknown}"
echo

############################################
# 1) Hard-code paths to tools (no conda activate)
############################################

TOPHAT2="/users/k25118204/.conda/envs/env5/bin/tophat2"
BOWTIE2="/users/k25118204/.conda/envs/env5/bin/bowtie2"

echo "Using TOPHAT2: $TOPHAT2"
echo "Using BOWTIE2: $BOWTIE2"
echo

if [ ! -x "$TOPHAT2" ]; then
  echo "ERROR: TOPHAT2 not found or not executable at: $TOPHAT2"
  exit 1
fi
if [ ! -x "$BOWTIE2" ]; then
  echo "ERROR: BOWTIE2 not found or not executable at: $BOWTIE2"
  exit 1
fi

#TopHat should find  bowtie2 on PATH
export PATH="$(dirname "$BOWTIE2"):$PATH"

############################################
# 2) Editable paths
############################################

GENOME_INDEX="genome_index/sacCer_SGD_R64-1-1"   # Bowtie2 index prefix (no .bt2)
FASTQ_DIR="01_fastq"                                # Folder with FASTQ files
OUTDIR="02_tophat_out"                              # TopHat outputs
LOGDIR="logs"                                    # Per-sample TopHat logs

mkdir -p "$OUTDIR" "$LOGDIR"

echo "[$(date)] Starting TopHat runs for all paired-end samples in: $FASTQ_DIR"
echo "Using genome index prefix: $GENOME_INDEX"
echo

############################################
# 3) Loop over all *_1.fastq files
############################################

for R1 in "$FASTQ_DIR"/*_1.fastq; do
    # If glob didn't match anything, exit
    [ -e "$R1" ] || { echo "No *_1.fastq files found in $FASTQ_DIR"; exit 1; }

    # Example R1: fastq/gln3-0_rep1_ERR3450094_1.fastq
    # BASE -> gln3-0_rep1_ERR3450094  (strip _1.fastq)
    BASE=$(basename "$R1" _1.fastq)

    # SAMPLE -> gln3-0_rep1  (strip _ERR3450094, everything from _ERR onwards)
    SAMPLE=${BASE%_ERR*}

    # R2: same BASE, but with _2.fastq
    # fastq/gln3-0_rep1_ERR3450094_2.fastq
    R2="${FASTQ_DIR}/${BASE}_2.fastq"

    if [ ! -f "$R2" ]; then
        echo "WARNING: No matching R2 for $R1 (expected $R2). Skipping sample $SAMPLE."
        echo
        continue
    fi

    echo ">>> Processing sample: $SAMPLE"
    echo "    R1: $R1"
    echo "    R2: $R2"
    echo

    SAMPLE_OUT="${OUTDIR}/${SAMPLE}"
    SAMPLE_LOG="${LOGDIR}/${SAMPLE}.log"

    # Clean any previous result
    rm -rf "$SAMPLE_OUT"
    mkdir -p "$SAMPLE_OUT"

    # -------- TopHat alignment (no -G) --------
    "$TOPHAT2" \
      --num-threads 2 \
      --no-coverage-search \
      -o "$SAMPLE_OUT" \
      "$GENOME_INDEX" \
      "$R1" "$R2" \
      > "$SAMPLE_LOG" 2>&1

    echo "Finished TopHat for $SAMPLE"
    echo "  Output: $SAMPLE_OUT"
    echo "  Log   : $SAMPLE_LOG"
    echo
done

echo "[$(date)] All TopHat runs completed."
