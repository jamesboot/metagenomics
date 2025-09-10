#!/bin/bash

# Script for running trimgalore on paired-end sequencing data
# using SLURM job scheduler with array jobs for multiple samples    
# Array size should be N lines in samplesheet.csv

#SBATCH --job-name=trimgalore
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=ncpu
#SBATCH --array=1-8

# Specify input file
PROJDIR=/nemo/stp/babs/working/bootj/projects/walle/marianne.shawetaylor/ms816
INPUT=${PROJDIR}/samplesheet.csv

# Specify output folders
OUTS=${PROJDOR}/trim
mkdir -p ${OUTS}

# Specify the parameters file containing sample names 
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT} | cut -d ',' -f 1)
R1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT} | cut -d ',' -f 2)
R2=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT} | cut -d ',' -f 3)

# Log
echo "Processing sheet:" ${INPUT}
echo "Sample:" ${SAMPLE} 
echo "R1_1:" ${R1}
echo "R2_1:" ${R2}

# Load trimgalore
ml TrimGalore/0.6.0

# Run trimgalore
trim_galore \
    --paired \
    --fastqc \
    --fastqc_args "--outdir ${OUTS}" \
    --output_dir ${OUTS} \
    --gzip \
    ${R1} ${R2}

# Create a samplesheet for bowtie2 alignment
bash /nemo/stp/babs/working/bootj/github/utilities/samplesheet.sh \
    -d ${OUTS} \
    -n \
    -o ${OUTS}/samplesheet.csv \
    -1 _1.fq.gz \
    -2 _2.fq.gz