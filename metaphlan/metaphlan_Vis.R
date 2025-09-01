# Script for processing kraken outputs

packageurl <- 'https://cran.r-project.org/src/contrib/Archive/stringi/stringi_1.8.3.tar.gz'
install.packages(packageurl, repos=NULL, type="source")

# Packages
library(tidyverse)
library(dplyr)

# List all samples
files <- list.files(
  path = 'metaphlan_outs',
  pattern = '_profile.txt',
  full.names = T,
  recursive = T
)

# Create sample names
samples <- gsub('metaphlan_outs/',
                '',
                gsub('_profile.txt',
                     '',
                     files))

# Create list
sampleList <- mapply(function(x, y) {list(x,y)}, samples, files, SIMPLIFY = F)

datList <- lapply(sampleList, function(x){
  # Read data
  dat <- read.delim(x[[2]],
                    skip = 5,
                    header = F,
                    col.names = c('Classification', 'Code', 'Percentage', 'Col2'))[1:2,]
  # Process
  datFilt <- dat %>%
    mutate(Sample = x[[1]])
  # Return
  return(datFilt)
})

# Merge data 
datAll <- do.call(rbind, datList)

# Plot
ggplot(datAll, aes(x = Sample, y = Percentage)) +
  geom_col(fill = '#31a354', colour = 'black') +
  facet_grid(rows = vars(Classification)) +
  scale_y_continuous(breaks =  seq(0, 100, by = 10)) +
  theme_bw() +
  ggtitle('Percentage reads Unclassified or classified to Bacteria')
ggsave(
  plot = last_plot(),
  filename = 'metaphlan_outs/Metaphlan_Summary.pdf',
  height = 4,
  width = 8
)

# Calculate diversity score for each sample
datList2 <- lapply(sampleList, function(x){
  # Read data
  dat <- read.delim(x[[2]],
                    skip = 5,
                    header = F,
                    col.names = c('Classification', 'Code', 'Percentage', 'Col2'))
  # Process
  datFilt <- dat %>%
    mutate(Sample = x[[1]]) 
  return(datFilt)
})

# rbind
diversity <- do.call(rbind, datList2)

#

diversity <- diversity %>%
  group_by(Sample) %>%
  select(c(Percentage, Sample)) %>%
  mutate(Proportion = Percentage / 100) %>%
  mutate(logProportion = log(Proportion)) %>%
  mutate(Product = Proportion * logProportion) %>%
  summarise(Sum = sum(Product)) %>%
  mutate(DiversityScore = -1 * Sum)  

# Plot
ggplot(diversity, aes(x = Sample, y = DiversityScore)) +
  geom_col(fill = '#31a354', colour = 'black') +
  scale_y_continuous(breaks =  seq(0, 4, by = 0.5)) +
  theme_bw() +
  ggtitle('Shannon diversity index of pilot samples')
ggsave(
  plot = last_plot(),
  filename = 'metaphlan_outs/Shannon_Diversity_Index.pdf',
  height = 4,
  width = 8
)

# Look at control samples in more detail
#Listeria monocytogenes - 12%, 
#Pseudomonas aeruginosa - 12%, 
#Bacillus subtilis - 12%, 
#Escherichia coli - 12%, 
#Salmonella enterica - 12%, 
#Lactobacillus fermentum - 12%, 
#Enterococcus faecalis - 12%, 
#Staphylococcus aureus - 12%, 
#Saccharomyces cerevisiae - 2%, 
#Cryptococcus neoformans - 2%.

controlSamps <- do.call(rbind, datList2)

controlSamps <- controlSamps %>%
  filter(Sample %in% c("WAL7102A7","WAL7102A8"))

toMatch <- c(
  'Listeria_monocytogenes',
  'Pseudomonas_aeruginosa',
  'Bacillus_subtilis',
  'Escherichia_coli',
  'Salmonella_enterica',
  'Lactobacillus_fermentum',
  'Enterococcus_faecalis',
  'Staphylococcus_aureus',
  'Saccharomyces_cerevisiae',
  'Cryptococcus_neoformans'
)

rows <- grep(paste(toMatch,collapse="|"), controlSamps$Classification)
controlSamps <- controlSamps[rows, ]
write.csv(controlSamps, 'metaphlan_outs/controlSamples.csv')







