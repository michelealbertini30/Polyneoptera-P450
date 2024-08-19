library(dplyr)

gene_table <- read.delim("Gene_table.tsv", header = TRUE, sep = "\t", stringsAsFactors = FALSE)
functions_table <- read.delim("Functions.tsv", header = FALSE, sep = "\t", stringsAsFactors = FALSE)

colnames(functions_table) <- c("Pattern", "Function")

gene_table$Function <- NA

assign_function <- function(id, patterns, functions) {
  for (i in seq_along(patterns)) {
    if (grepl(patterns[i], id)) {
      return(functions[i])
    }
  }
  return(NA)
}

gene_table$Function <- mapply(assign_function, gene_table$Id, MoreArgs = list(patterns = functions_table$Pattern, functions = functions_table$Function))

##Apply functions on a treefile
library(ape)
library(ggtree)

tree <- read.tree("P450.rnd1.tree")
gene_family_data <- gene_table[, c(1,4)]

# Convert tree tip labels to a data frame
tip_labels <- data.frame(Tip = tree$tip.label)

# Merge with gene family data
merged_data <- merge(tip_labels, gene_family_data, by = "Tip", all.x = TRUE)

# Create a color palette
gene_families <- unique(merged_data$Function)

colors <- c("Plant toxins metabolism" = "blue",
            "Furanocumarins metabolism" = "azure",
            "Cuticular hydrocarbon synthesis" = "orange", 
            "Halloween" = "limegreen", 
            "Ecdysteroid hydroxilase" = "lightgreen", 
            "Methyl-farnesoate epoxidase" = "darkred",
            "Defensive compounds synthesis" = "red",
            "Pyrethroid metabolism" = "darkblue",
            "Omega-oxidation of fatty acids" = "gold",
            "Terpenes metabolism" = "lightblue",
            "Ecdysone monooxygenase" = "purple",
            "Catalyze reduction of CYPs" = "pink",
            "Uncharacterized" = NA,
            "Unassigned" = NA)

# Plot the tree
p <- ggtree(tree, layout = "circular", linetype = "solid", size = 0.1, color = "#929292")

# Add the gene family information to the tree plot
p <- p %<+% merged_data

p <- p + 
  geom_point2(aes(subset = isTip, x = x+0.1, y = y, color = Function), size = 1, shape = 15) +
  scale_color_manual(values = colors, na.value = "transparent") +
  theme(legend.position = "right")

print(p)

