#!/bin/bash

# bwa_markdup_mapper.sh
# Description: Process single- or paired-end trimmed FASTQ files with BWA + samtools + sambamba.
# Output: Deduplicated, indexed BAM files + logs + summary table.

set -euo pipefail

# ============
# USER CONFIG
# ============
REF="/path/to/reference.fasta"
TRIMMED_DIR="/path/to/trimmed_fastq"
OUTDIR_BASE="/path/to/output"
THREADS=24
SORT_THREADS=16
# ============

# Parse args
SAMPLE_LIST="$1"
[[ ! -f "$SAMPLE_LIST" ]] && echo "Sample list not found: $SAMPLE_LIST" && exit 1

# Create directory structure
BWA_OUT="${OUTDIR_BASE}/bwa"
MD_OUT="${OUTDIR_BASE}/sambamba"
TEMP_DIR="${OUTDIR_BASE}/temp"
LOG_DIR="${OUTDIR_BASE}/logs"
SUMMARY="${LOG_DIR}/mapping_summary.tsv"
mkdir -p "$BWA_OUT" "$MD_OUT" "$TEMP_DIR" "$LOG_DIR"
echo -e "Sample\tType\tStatus\tFinal_BAM_Size_MB" > "$SUMMARY"

# Loop through samples
while read -r SAMPLE; do
    echo "Processing $SAMPLE..."
    LOG_FILE="${LOG_DIR}/${SAMPLE}.log"

    PE_R1="${TRIMMED_DIR}/${SAMPLE}_R1_trimmed.fastq.gz"
    PE_R2="${TRIMMED_DIR}/${SAMPLE}_R2_trimmed.fastq.gz"
    SE_READ="${TRIMMED_DIR}/${SAMPLE}_trimmed.fastq.gz"
    BAM="${BWA_OUT}/${SAMPLE}.bam"
    MD_BAM="${MD_OUT}/${SAMPLE}.MD.bam"
    TEMP_PREFIX="${TEMP_DIR}/${SAMPLE}"

    {
        if [[ -f "$PE_R1" && -f "$PE_R2" ]]; then
            echo "Paired-end detected."
            TYPE="PE"
            bwa mem -R "@RG\tID:$SAMPLE\tSM:$SAMPLE\tPL:ILLUMINA\tPU:$SAMPLE\tLB:$SAMPLE" -t $THREADS \
                "$REF" "$PE_R1" "$PE_R2" \
                | samtools sort -@${SORT_THREADS} -T "${TEMP_PREFIX}.sort" -o "$BAM"

        elif [[ -f "$SE_READ" ]]; then
            echo "Single-end detected."
            TYPE="SE"
            bwa mem -R "@RG\tID:$SAMPLE\tSM:$SAMPLE\tPL:ILLUMINA\tPU:$SAMPLE\tLB:$SAMPLE" -t $THREADS \
                "$REF" "$SE_READ" \
                | samtools sort -@${SORT_THREADS} -T "${TEMP_PREFIX}.sort" -o "$BAM"

        else
            echo "Input files not found for $SAMPLE. Skipping."
            echo -e "$SAMPLE\tNA\tMissing input\tNA" >> "$SUMMARY"
            exit 0
        fi

        sambamba markdup --tmpdir="$TEMP_DIR" -t ${SORT_THREADS} "$BAM" "$MD_BAM"
        samtools index "$MD_BAM"
        SIZE_MB=$(du -m "$MD_BAM" | cut -f1)

        rm -f "$BAM"

        echo -e "$SAMPLE\t$TYPE\tSuccess\t$SIZE_MB" >> "$SUMMARY"
    } &> "$LOG_FILE"

done < "$SAMPLE_LIST"
