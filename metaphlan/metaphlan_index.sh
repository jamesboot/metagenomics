#!/bin/bash

#SBATCH --job-name=metaphlan
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=ncpu
#SBATCH --ntasks=1
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=james.boot@crick.ac.uk

# Load Anaconda module
ml Anaconda3/2023.09-0

# Specify output folder
OUTS=metaphlan_db
mkdir -p ${OUTS}

# Activate env
source activate metaphlan

# Run metaphlan
metaphlan --install --bowtie2db ${OUTS}