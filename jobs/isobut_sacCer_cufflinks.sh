#!/bin/bash
#SBATCH --job-name=isobut_cufflinks
#SBATCH --output=logs/cufflinks/%x_%j.out
#SBATCH --error=logs/cufflinks/%x_%j.err
#SBATCH --time=4:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4
#SBATCH -p msc_appbio

set -euo pipefail

echo "[$(date)] Cufflinks job started on host: $(hostname)"
echo "SLURM_JOB_ID = ${SLURM_JOB_ID:-unknown}"
echo

############################################
# 1) Path to Cufflinks binary
############################################

CUFFLINKS="/users/k25118204/.conda/envs/env5/bin/cufflinks"

echo "Using CUFFLINKS: $CUFFLINKS"
echo

if [ ! -x "$CUFFLINKS" ]; then
  echo "ERROR: cufflinks not found or not executable at: $CUFFLINKS"
  exit 1
fi

############################################
# 2) Reference annotation (GTF) - adjust if your filename differs
############################################

GTF="reference/sacCer_SGD_R64-1-1.NCnames.gtf"

if [ ! -f "$GTF" ]; then
  echo "ERROR: GTF file not found at: $GTF"
  exit 1
fi

############################################
# 3) Directories
############################################

PICARD_DIR="03_picard"     # from previous step
CUFF_DIR="04_cufflinks"    # new output dir for Cufflinks

mkdir -p "$CUFF_DIR" logs

echo "Picard-cleaned BAM dir : $PICARD_DIR"
echo "Cufflinks output dir   : $CUFF_DIR"
echo "Annotation GTF         : $GTF"
echo

############################################
# 4) Loop over all *_dedup.bam files
############################################

for BAM in "$PICARD_DIR"/*_dedup.bam; do
    # If glob didn't match anything, bail
    [ -e "$BAM" ] || { echo "No *_dedup.bam files found in $PICARD_DIR"; exit 1; }

    # Example BAM: 03_picard/gln3-0_rep1_dedup.bam
    # SAMPLE -> gln3-0_rep1
    SAMPLE=$(basename "$BAM" _dedup.bam)

    echo ">>> Processing sample: $SAMPLE"
    echo "    BAM: $BAM"
    echo

    SAMPLE_OUT="${CUFF_DIR}/${SAMPLE}_cufflinks"
    SAMPLE_LOG="logs/cufflinks_${SAMPLE}.log"

    # Clean any previous run for this sample
    rm -rf "$SAMPLE_OUT"
    mkdir -p "$SAMPLE_OUT"

    # -------- Cufflinks run (reference-guided, with GTF) --------
    "$CUFFLINKS" \
      -p 4 \
      -G "$GTF" \
      -o "$SAMPLE_OUT" \
      "$BAM" \
      > "$SAMPLE_LOG" 2>&1

    echo "Finished Cufflinks for $SAMPLE"
    echo "  Output dir: $SAMPLE_OUT"
    echo "  Log file  : $SAMPLE_LOG"
    echo
done

echo "[$(date)] All Cufflinks runs completed."
