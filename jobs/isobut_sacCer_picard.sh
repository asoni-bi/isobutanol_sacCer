#!/bin/bash
#SBATCH --job-name=isobut_sacCer_picard
#SBATCH --output=logs/picard/picard_%x_%j.out
#SBATCH --error=logs/picard/picard_%x_%j.err
#SBATCH --time=8:00:00
#SBATCH --mem=10G
#SBATCH --cpus-per-task=2
#SBATCH -p msc_appbio

set -euo pipefail

echo "[$(date)] Picard job started on host: $(hostname)"
echo "SLURM_JOB_ID = ${SLURM_JOB_ID:-unknown}"
echo

############################################
# 1) Hard-code path to Picard (no conda activate)
############################################

PICARD="/users/k25118204/.conda/envs/env5/bin/picard"

echo "Using PICARD: $PICARD"
echo

if [ ! -x "$PICARD" ]; then
  echo "ERROR: picard not found or not executable at: $PICARD"
  exit 1
fi

############################################
# 2) Directories
############################################

TOPHAT_DIR="02_tophat_out"   # where accepted_hits.bam live
PICARD_DIR="03_picard"    # output for all Picard files

mkdir -p "$PICARD_DIR" logs

echo "TopHat directory : $TOPHAT_DIR"
echo "Picard output dir: $PICARD_DIR"
echo

############################################
# 3) Loop over all samples with accepted_hits.bam
############################################

# Pattern: tophat_out/SAMPLE/accepted_hits.bam
for BAM in "$TOPHAT_DIR"/*/accepted_hits.bam; do
    # If glob doesn't match anything, skip
    [ -e "$BAM" ] || { echo "No accepted_hits.bam files found under $TOPHAT_DIR"; exit 1; }

    # SAMPLE = folder name under tophat_out
    # e.g. tophat_out/gln3-0_rep1/accepted_hits.bam -> gln3-0_rep1
    SAMPLE=$(basename "$(dirname "$BAM")")

    echo ">>> Processing sample: $SAMPLE"
    echo "    Input BAM: $BAM"
    echo

    SORTED_BAM="${PICARD_DIR}/${SAMPLE}_sorted.bam"
    DEDUP_BAM="${PICARD_DIR}/${SAMPLE}_dedup.bam"
    METRICS_TXT="${PICARD_DIR}/${SAMPLE}_metrics.txt"
    VALIDATE_TXT="${PICARD_DIR}/${SAMPLE}_validate.txt"

    ########################################
    # Step 1: Sort BAM by coordinate
    ########################################
    echo "  [1/4] SortSam -> $SORTED_BAM"

    "$PICARD" SortSam \
        INPUT="$BAM" \
        OUTPUT="$SORTED_BAM" \
        SORT_ORDER=coordinate

    ########################################
    # Step 2: Remove PCR duplicates
    ########################################
    echo "  [2/4] MarkDuplicates -> $DEDUP_BAM"

    "$PICARD" MarkDuplicates \
        INPUT="$SORTED_BAM" \
        OUTPUT="$DEDUP_BAM" \
        METRICS_FILE="$METRICS_TXT" \
        REMOVE_DUPLICATES=true \
        ASSUME_SORTED=true

    ########################################
    # Step 3: Build BAM index (.bai)
    ########################################
    echo "  [3/4] BuildBamIndex for $DEDUP_BAM"

    "$PICARD" BuildBamIndex \
        INPUT="$DEDUP_BAM"

    ########################################
    # Step 4: Validate cleaned BAM
    ########################################
    echo "  [4/4] ValidateSamFile -> $VALIDATE_TXT"

    "$PICARD" ValidateSamFile \
        INPUT="$DEDUP_BAM" \
        MODE=SUMMARY \
        OUTPUT="$VALIDATE_TXT" \
      || echo "  NOTE: Validation reported issues for $SAMPLE (see $VALIDATE_TXT), continuing."

    echo "Finished Picard processing for $SAMPLE"
    echo "  Sorted BAM   : $SORTED_BAM"
    echo "  Dedup BAM    : $DEDUP_BAM"
    echo "  Index        : ${DEDUP_BAM}.bai"
    echo "  Metrics      : $METRICS_TXT"
    echo "  Validation   : $VALIDATE_TXT"
    echo
done

echo "[$(date)] All Picard steps completed for all samples."


