#!/bin/bash

#SBATCH --job-name=kraken
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=ncpu
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=james.boot@crick.ac.uk
#SBATCH --array=1-8

# Specify input files
INPUT1=samplesheet_B22TTNWLT3.csv
DBNAME=kraken2_standard_db

# Specify output folders
META_OUTS=kraken_outs
TRIM_OUTS=trimgalore_outs
mkdir -p ${META_OUTS}
mkdir -p ${TRIM_OUTS}

# Specify the parameters file containing sample names 
SAMPLE_1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT1} | cut -d ',' -f 1)

# Log
echo "Sample_1:" ${SAMPLE_1}

# Define input files
META_R1=${TRIM_OUTS}/${SAMPLE_1}_R1_val_1.fq.gz
META_R2=${TRIM_OUTS}/${SAMPLE_1}_R2_val_2.fq.gz

# Load Anaconda module
ml Anaconda3/2023.09-0

# Activate env
source activate kraken2 

# Run kraken2
kraken2 --db ${DBNAME} \
--threads ${SLURM_CPUS_PER_TASK} \
--fastq-input \
--gzip-compressed \
--paired \
--report ${META_OUTS}/${SAMPLE_1}_report.txt \
${META_R1} ${META_R2} > ${META_OUTS}/${SAMPLE_1}.kraken