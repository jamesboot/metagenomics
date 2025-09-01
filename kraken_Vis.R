# Script for processing kraken outputs

# Packages
library(tidyverse)
library(dplyr)
library(stringr)

# List all samples
files <- list.files(
  path = 'kraken_outs',
  pattern = '_report.txt',
  full.names = T,
  recursive = T
)

# Create sample names
samples <- gsub('kraken_outs/',
                '',
                gsub('_report.txt',
                     '',
                     files))

# Create list
sampleList <- mapply(function(x, y) {list(x,y)}, samples, files, SIMPLIFY = F)

# Set taxon code
# D = Domain for eukaryote etc.
# G = Genus 
TaxonCode <- 'D'
#TaxonCode <- 'G'

# Process all samples
datList <- lapply(sampleList, function(x){
  # Read data
  dat <- read.delim(x[[2]],
                    header = F,
                    col.names = c(
                      'Percentage',
                      'Clade_reads',
                      'Taxon_reads',
                      'Taxon_code',
                      'NCBI_code',
                      'Name'
                    ))
  
  # Process
  dat$Name <- str_trim(dat$Name, 'both')
  
  datFilt <- dat %>%
    filter(Taxon_code == TaxonCode) %>%
    mutate(Sample = x[[1]])
  
  return(datFilt)
})

# Merge data 
datAll <- do.call(rbind, datList)

# Decide what to plot
if (TaxonCode == 'G') {
  # Plot human alignment percentage
  humanPlt <- datAll %>%
    filter(Name == 'Homo')
  ggplot(humanPlt, aes(x = Sample, y = Percentage)) +
    geom_col(fill = '#31a354', colour = 'black') +
    scale_y_continuous(breaks =  seq(0, 100, by = 10)) +
    theme_bw() +
    ggtitle('Percentage reads classified as Human in pilot samples')
  ggsave(
    plot = last_plot(),
    filename = 'kraken_outs/Homo_Sapiens_Alignment.pdf',
    height = 4,
    width = 8
  )
  # Diversity score (0 = no diversity)
  diversityScore <- datAll %>%
    group_by(Sample) %>%
    mutate(SampleSum = sum(Clade_reads)) %>%
    mutate(Proportion = Clade_reads/SampleSum) %>%
    mutate(logProportion = log(Proportion)) %>%
    mutate(Product = Proportion*logProportion) %>%
    summarise(Sum = sum(Product)) %>%
    mutate(DiversityScore = -1*Sum)
  # Plot
  ggplot(diversityScore, aes(x = Sample, y = DiversityScore)) +
    geom_col(fill = '#31a354', colour = 'black') +
    scale_y_continuous(breaks =  seq(0, 0.5, by = 0.05)) +
    theme_bw() +
    ggtitle('Shannon diversity index of pilot samples')
  ggsave(
    plot = last_plot(),
    filename = 'kraken_outs/Shannon_Diversity_Index.pdf',
    height = 4,
    width = 8
  )
} else if (TaxonCode == 'D') {
  # Plot D level stacked bar chart
  datAll$Name <- factor(datAll$Name,
                        levels = c("Eukaryota", "Bacteria", "Archaea", "Viruses"))
  ggplot(datAll, aes(x = Sample, y = Clade_reads, fill = Name)) +
    geom_bar(colour = 'black',
             position = "dodge",
             stat = "identity") +
    theme_bw() +
    ggtitle('Number of reads classified to each Domain')
  ggsave(plot = last_plot(), 
         filename = 'kraken_outs/Domain_Alignment1.pdf',
         height = 4,
         width = 10)
  ggplot(datAll, aes(x = Sample, y = Clade_reads, fill = Name)) +
    geom_bar(colour = 'black',
             position = "fill",
             stat = "identity") +
    theme_bw() +
    ggtitle('Number of reads classified to each Domain')
  ggsave(plot = last_plot(), 
         filename = 'kraken_outs/Domain_Alignment2.pdf',
         height = 4,
         width = 10)
}

# Look at control samples

# Process all samples
datList <- lapply(sampleList, function(x){
  # Read data
  dat <- read.delim(x[[2]],
                    header = F,
                    col.names = c(
                      'Percentage',
                      'Clade_reads',
                      'Taxon_reads',
                      'Taxon_code',
                      'NCBI_code',
                      'Name'
                    ))
  
  # Process
  dat$Name <- str_trim(dat$Name, 'both')
  # Add sample col
  dat <- dat %>%
    mutate(Sample = x[[1]])
  # Return
  return(dat)
})

controls <- do.call(rbind, datList[c('WAL7102A7', 'WAL7102A8')])

controls <- controls %>%
  filter(Taxon_code == 'G')

toMatch <- c(
  'Listeria',
  'Pseudomonas',
  'Bacillus',
  'Escherichia',
  'Salmonella',
  'Lactobacillus',
  'Enterococcus',
  'Staphylococcus',
  'Saccharomyces',
  'Cryptococcus'
)

rows <- grep(paste(toMatch,collapse="|"), controls$Name)
controlSamps <- controls[rows, ]
write.csv(controlSamps, 'kraken_outs/controlSamples.csv')


