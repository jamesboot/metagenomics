# metagenomics

Scripts for metagenomics analysis

## `preprocessing`

- `trimgalore.sh` script for read trimming, runs as a slurm array, samplesheet required as input, expected output are trimmed reads and a new samplesheet. Depends on `samplesheet.sh` script in `github:jamesboot/utilities`
- `bwt2_pe_host_depl.sh` script for host read removal using bowtie2, paired end reads. Requires the output from `trimgalore.sh`