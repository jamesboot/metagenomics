#!/bin/bash

# Script for running bowtie2 on paired-end sequencing data
# to remove host contamination using SLURM job scheduler with array jobs for multiple samples    
# Array size should be N lines in samplesheet.csv  
# Run trimgalore first to generate samplesheet.csv and trim reads

#SBATCH --job-name=bowtie2_pe_host_depl
#SBATCH --output=../logs/bowtie2_pe_host_depl-%j.txt
#SBATCH --time=6-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=ncpu
#SBATCH --array=1-5

# Input files and directories
PROJDIR=/nemo/stp/babs/working/bootj/projects/riglard/will.mckenny/wm949
SAMPLESHEET=${PROJDIR}/data/sample-sheets/trim_samplesheet.csv
GENOME=/nemo/stp/babs/reference/Genomics/babs/mus_musculus/ensembl/GRCm38/release-95/genome_idx/bowtie2/Mus_musculus.GRCm38.dna_sm.toplevel
OUTPUT_DIR=${PROJDIR}/analysis/standard_template/outputs/bowtie2

# Specify the parameters file containing sample names 
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLESHEET} | cut -d ',' -f 1)
R1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLESHEET} | cut -d ',' -f 2)
R2=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLESHEET} | cut -d ',' -f 3)

# Load modules
ml Bowtie2/2.5.1-GCC-12.3.0
ml SAMtools/1.18-GCC-12.3.0

# Log
echo "SAMPLE: ${SAMPLE}"
echo "R1: ${R1}"
echo "R2: ${R2}"

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Run bowtie2
echo "Running bowtie2..."
bowtie2 -p ${SLURM_CPUS_PER_TASK} -x ${GENOME} \
    -1 ${R1} \
    -2 ${R2} \
    --very-sensitive-local \
    -S ${OUTPUT_DIR}/${SAMPLE}_mapped_and_unmapped.sam

# Collect stats
echo "Collecting stats..."
samtools flagstat ${OUTPUT_DIR}/${SAMPLE}_mapped_and_unmapped.sam > ${OUTPUT_DIR}/${SAMPLE}_stats.txt

# Convert sam to bam
echo "Converting sam to bam..."
samtools view -bS ${OUTPUT_DIR}/${SAMPLE}_mapped_and_unmapped.sam > ${OUTPUT_DIR}/${SAMPLE}_mapped_and_unmapped.bam

# Remove un-needed files
rm ${OUTPUT_DIR}/${SAMPLE}_mapped_and_unmapped.sam

# Filter to unmapped reads
# -f 12 = Extract only alignments with both reads unmapped
# -F 256 = Do not extract alignments which are: <not primary alignment>
echo "Filtering to unmapped only..."
samtools view -b -f 12 -F 256 \
    ${OUTPUT_DIR}/${SAMPLE}_mapped_and_unmapped.bam \
    > ${OUTPUT_DIR}/${SAMPLE}_bothReadsUnmapped.bam

# Remove un-needed files
rm ${OUTPUT_DIR}/${SAMPLE}_mapped_and_unmapped.bam

# Split back into separate fastq files for each read
echo "Splitting R1 and R2 into fastq files..."
samtools sort -n \
    -o ${OUTPUT_DIR}/${SAMPLE}_bothReadsUnmapped_sorted.bam \
    ${OUTPUT_DIR}/${SAMPLE}_bothReadsUnmapped.bam

# Remove un-needed files
rm ${OUTPUT_DIR}/${SAMPLE}_bothReadsUnmapped.bam

samtools fastq \
    -1 ${OUTPUT_DIR}/${SAMPLE}_host_removed_R1.fastq.gz \
    -2 ${OUTPUT_DIR}/${SAMPLE}_host_removed_R2.fastq.gz \
    -0 /dev/null -s /dev/null -n \
    ${OUTPUT_DIR}/${SAMPLE}_bothReadsUnmapped_sorted.bam

# Remove un-needed files
rm ${OUTPUT_DIR}/${SAMPLE}_bothReadsUnmapped_sorted.bam