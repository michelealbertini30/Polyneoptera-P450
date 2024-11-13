# Load necessary library
library(dplyr)
library(tidyr)

# Example dataframe
Gene_table <- read.delim("Gene_table.tsv", header = TRUE, sep="\t")
df <- Gene_table[, c(1,3)]

# Extract species from Tip
df <- df %>%
  mutate(Species = sub(".*\\.", "", Tip))

# Count instances of each GeneFamily for each Species
result <- df %>%
  group_by(Species, GeneFamily) %>%
  summarise(Count = n()) %>%
  spread(GeneFamily, Count, fill = 0)

# Rename the columns
result <- result %>%
  rename(ID = Species)

CYPome <- result[, c(1,3,5,6,7,8)]

write.table(CYPome, file = "CYPome.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
