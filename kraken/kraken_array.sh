#!/bin/bash

#SBATCH --job-name=kraken
#SBATCH --output=../logs/kraken-%j.txt
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=ncpu
#SBATCH --array=1-5

# Specify input and output directories/files
PROJDIR=/nemo/stp/babs/working/bootj/projects/riglard/will.mckenny/wm949
INPUT=${PROJDIR}/data/sample-sheets/samplesheet.csv
DBNAME=/nemo/stp/babs/working/bootj/genomes/kraken2
FASTQDIR=${PROJDIR}/analysis/standard_template/outputs/bowtie2
META_OUTS=${PROJDIR}/analysis/standard_template/outputs/kraken

# Create output folders
mkdir -p ${META_OUTS}

# Specify the parameters file containing sample names 
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT} | cut -d ',' -f 1)

# Log
echo "Sample:" ${SAMPLE}

# Define input files
R1=${FASTQDIR}/${SAMPLE}_host_removed_R1.fastq.gz
R2=${FASTQDIR}/${SAMPLE}_host_removed_R2.fastq.gz

# Load Anaconda module
ml Anaconda3/2023.09-0

# Activate env
source activate kraken2 

# Run kraken2
kraken2 --db ${DBNAME} \
--threads ${SLURM_CPUS_PER_TASK} \
--gzip-compressed \
--paired \
--report ${META_OUTS}/${SAMPLE}_report.txt \
${R1} ${R2} > ${META_OUTS}/${SAMPLE}.kraken