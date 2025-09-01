#!/bin/bash

#SBATCH --job-name=krakenDB
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
OUTS=kraken_standard_db
mkdir -p ${OUTS}

# Activate env
source activate kraken2 

# Run metaphlan
kraken2-build --standard --threads ${SLURM_CPUS_PER_TASK} --db ${OUTS}