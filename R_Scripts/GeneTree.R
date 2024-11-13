library(ape)
library(ggtree)
library(dplyr)

tree <- read.tree("P450.rnd1.tree")
#gene_family_data <- read.delim("Drosophila.gene.id", header = TRUE, sep = "\t")
Gene_table <- read.delim("Gene_table.tsv", header = TRUE, sep="\t")
gene_family_data <- Gene_table[, c(1,3)]

#all_tips <- tree$tip.label
#unassigned_tips <- setdiff(all_tips, gene_family_data$Tip)
#unassigned_data <- data.frame(Tip = unassigned_tips, GeneFamily = NA)

#df <- unassigned_data %>%
#  mutate(GeneFamily = ifelse(is.na(GeneFamily), "Unassigned", names))

#gene_family <- rbind(gene_family_data, df)

# Convert tree tip labels to a data frame
tip_labels <- data.frame(Tip = tree$tip.label)

# Merge with gene family data
merged_data <- merge(tip_labels, gene_family_data, by = "Tip", all.x = TRUE)

# Create a color palette
gene_families <- unique(merged_data$GeneFamily)

colors <- c("Clan_2" = "limegreen", 
            "Clan_3" = "orange", 
            "Clan_4" = "steelblue", 
            "Clan_M" = "red", 
            "Clan_R" = "pink",
            "Uncharacterized" = NA,
            "Unassigned" = NA)

# Plot the tree
p <- ggtree(tree, layout = "circular", linetype = "solid", size = 0.1, color = "#929292")

# Add the gene family information to the tree plot
p <- p %<+% merged_data

p <- p + 
  geom_point2(aes(subset = isTip, x = x+0.1, y = y, color = GeneFamily), size = 1, shape = 15) +
  scale_color_manual(values = colors, na.value = "transparent") 
  theme(legend.position = "right")

p <- p + 
  geom_tree(aes(color = GeneFamily), size = 0.1) +
  scale_color_manual(values = colors, na.value = "transparent") + 
  theme(legend.position = "right")  
  
print(p)
