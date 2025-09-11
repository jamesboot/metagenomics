#!/bin/bash

#SBATCH --job-name=krakenDB
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=ncpu
#SBATCH --ntasks=1

# Specify project directory and output folder
PROJDIR=/nemo/stp/babs/working/bootj/projects/riglard/will.mckenny/wm949
OUTS=${PROJDIR}/data/external/kraken_standard_db

# Load Anaconda module
ml Anaconda3/2023.09-0

# Create output folder
mkdir -p ${OUTS}

# Activate env
source activate kraken2 

# Run metaphlan
kraken2-build --standard --threads ${SLURM_CPUS_PER_TASK} --db ${OUTS}