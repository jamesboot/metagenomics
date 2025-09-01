#!/bin/bash

#SBATCH --job-name=metaphlan
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=ncpu
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=james.boot@crick.ac.uk
#SBATCH --array=1-8

# Specify input file
INPUT1=samplesheet_B22TTNWLT3.csv
INPUT2=samplesheet_A22T3TTLT.csv

# Specify output folders
META_OUTS=metaphlan_outs
TRIM_OUTS=trimgalore_outs
FASTQ_OUTS=fastq_merge_outs
mkdir -p ${META_OUTS}
mkdir -p ${TRIM_OUTS}
mkdir -p ${FASTQ_OUTS}

# Specify the parameters file containing sample names 
SAMPLE_1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT1} | cut -d ',' -f 1)
R1_1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT1} | cut -d ',' -f 2)
R2_1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT1} | cut -d ',' -f 3)
SAMPLE_2=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT2} | cut -d ',' -f 1)
R1_2=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT2} | cut -d ',' -f 2)
R2_2=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${INPUT2} | cut -d ',' -f 3)

# Log
echo "Sample_1:" ${SAMPLE_1}
echo "Sample_2:" ${SAMPLE_2}
echo "R1_1:" ${R1_1}
echo "R1_2:" ${R1_2}
echo "R2_1:" ${R2_1}
echo "R2_2:" ${R2_2}

# Concat fastq files
cat ${R1_1} ${R1_2} > ${FASTQ_OUTS}/${SAMPLE_1}_R1.fastq.gz
cat ${R2_1} ${R2_2} > ${FASTQ_OUTS}/${SAMPLE_1}_R2.fastq.gz

# Define inputs for trimgalore
TRIM_R1=${FASTQ_OUTS}/${SAMPLE_1}_R1.fastq.gz
TRIM_R2=${FASTQ_OUTS}/${SAMPLE_1}_R2.fastq.gz

# Load trimgalore
ml TrimGalore/0.6.0

# Run trimgalore
trim_galore \
--paired \
--fastqc \
--fastqc_args "--outdir ${TRIM_OUTS}" \
--output_dir ${TRIM_OUTS} \
--gzip \
${TRIM_R1} ${TRIM_R2}

# Purge
ml purge

# Define next input files
META_R1=${TRIM_OUTS}/${SAMPLE_1}_R1_val_1.fq.gz
META_R2=${TRIM_OUTS}/${SAMPLE_1}_R2_val_2.fq.gz

# Load Anaconda module
ml Anaconda3/2023.09-0

# Activate env
source activate metaphlan

# Run metaphlan
metaphlan ${META_R1},${META_R2} \
--nproc ${SLURM_CPUS_PER_TASK} \
--bowtie2out ${META_OUTS}/${SAMPLE_1}.bowtie2.bz2 \
--input_type fastq \
--unclassified_estimation \
-o ${META_OUTS}/${SAMPLE_1}_profile.txt \
--bowtie2db metaphlan_db