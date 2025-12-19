#!/bin/bash
#########################################################################
# Cuffdiff differential expression job
# Group6_ABCC - gln3Δ vs WT under isobutanol
#########################################################################
#SBATCH --job-name=cuffdiff_isobut
#SBATCH --output=logs/cuffdiff/%x_%j.out
#SBATCH --error=logs/cuffdiff/%x_%j.err
#SBATCH --time=04:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH -p msc_appbio

set -euo pipefail

echo "[$(date)] Starting Cuffdiff on host: $(hostname)"
echo "JOB ID: ${SLURM_JOB_ID:-none}"
echo

##############################################
# 1) Paths
##############################################

BASE=/scratch/grp/msc_appbio/Group6_ABCC
BAMDIR=$BASE/03_picard
REF_GTF=$BASE/reference/sacCer_SGD_R64-1-1.NCnames.gtf
OUTDIR=$BASE/05_cuffdiff/WT_iso_vs_WT_0

CUFFDIFF=$(which cuffdiff)

echo "Cuffdiff binary: $CUFFDIFF"
echo "BAM directory  : $BAMDIR"
echo "Reference GTF  : $REF_GTF"
echo "Output dir     : $OUTDIR"
echo

# Validate inputs
if [ ! -x "$CUFFDIFF" ]; then
  echo "ERROR: cuffdiff binary not found in env."
  exit 1
fi

if [ ! -f "$REF_GTF" ]; then
  echo "ERROR: GTF file missing: $REF_GTF"
  exit 1
fi

# Create output dir
mkdir -p "$OUTDIR"
mkdir -p logs

# Two replicates of gln3Δ + isobutanol
GLN3_ISO="$BAMDIR/gln3-i-BuOH_rep1_dedup.bam,$BAMDIR/gln3-i-BuOH_rep2_dedup.bam"

# Two replicates of WT + isobutanol
WT_ISO="$BAMDIR/WT-i-BuOH_rep1_dedup.bam,$BAMDIR/WT-i-BuOH_rep2_dedup.bam"

# Two replicates of gln3_0
GLN3_0="$BAMDIR/gln3-0_rep1_dedup.bam,$BAMDIR/gln3-0_rep2_dedup.bam"

# Two replicates of WT_0
WT_0="$BAMDIR/WT-0_rep1_dedup.bam,$BAMDIR/WT-0_rep2_dedup.bam"


##############################################
# 2) Run Cuffdiff: gln3Δ + iso vs WT + iso
##############################################

# Two replicates of gln3Δ + isobutanol
#GLN3_ISO="$BAMDIR/gln3-i-BuOH_rep1_dedup.bam,$BAMDIR/gln3-i-BuOH_rep2_dedup.bam"

# Two replicates of WT + isobutanol
#WT_ISO="$BAMDIR/WT-i-BuOH_rep1_dedup.bam,$BAMDIR/WT-i-BuOH_rep2_dedup.bam"

#echo "Running Cuffdiff..."
#echo "Group1 (gln3_iso): $GLN3_ISO"
#echo "Group2 (WT_iso)  : $WT_ISO"
#echo

#$CUFFDIFF \
#  -o "$OUTDIR" \
#  -p 4 \
#  -L gln3_iso,WT_iso \
#  -u "$REF_GTF" \
#  $GLN3_ISO \
#  $WT_ISO

#echo
#echo "[$(date)] Cuffdiff completed successfully."
#echo "Results in: $OUTDIR"

##############################################
# 3) Run Cuffdiff: gln3Δ no iso vs WT no iso
##############################################
#echo "Running Cuffdiff..."
#echo "Group1 (gln3_0): $GLN3_0"
#echo "Group2 (WT_0)  : $WT_0"
#echo
#$CUFFDIFF \
#  -o "$OUTDIR" \
#  -p 4 \
#  -L gln3_0,WT_0 \
#  -u "$REF_GTF" \
#  $GLN3_0 \
#  $WT_0
#echo
#echo "[$(date)] Cuffdiff completed successfully."
#echo "Results in: $OUTDIR"

##############################################
# 4) Run Cuffdiff: gln3Δ + iso vs gln3Δ no iso
##############################################
#echo "Running Cuffdiff..."
#echo "Group1 (gln3_iso): $GLN3_ISO"
#echo "Group2 (gln3_0)  : $GLN3_0"
#echo 
#$CUFFDIFF \
#  -o "$OUTDIR" \
#  -p 4 \
#  -L gln3_iso,gln3_0 \
#  -u "$REF_GTF" \
#  $GLN3_ISO \
#  $GLN3_0
#echo
#echo "[$(date)] Cuffdiff completed successfully."
#echo "Results in: $OUTDIR"

##############################################
# 5) Run Cuffdiff: WT_iso vs WT_0
##############################################
echo "Running Cuffdiff..."
echo "Group1 (WT_iso): $WT_ISO"
echo "Group2 (WT_0)  : $WT_0"
echo 
$CUFFDIFF \
  -o "$OUTDIR" \
  -p 4 \
  -L WT_iso,WT_0 \
  -u "$REF_GTF" \
  $WT_ISO \
  $WT_0
echo
echo "[$(date)] Cuffdiff completed successfully."
echo "Results in: $OUTDIR"
