library(ggplot2)
library(tidyr)
library(ggtree)
library(cowplot)

P450.clan <- read.delim("C:/Users/utente/OneDrive/Desktop/CYPome.tsv")

tree <- read.tree("species_tree_polyneoptera.treefile")
tip_labels <- tree$tip.label

data_long <- gather(P450.clan, key = "CYP", value = "Count", CYP2:CYPR)

data_long$ID <- factor(data_long$ID, levels = tip_labels)

unique_cyp_levels <- unique(data_long$CYP)
reversed_cyp_levels <- rev(unique_cyp_levels)
data_long$CYP <- factor(data_long$CYP, levels = reversed_cyp_levels)

colors <- c("CYP2" = "limegreen", 
            "CYP3" = "orange", 
            "CYP4" = "steelblue", 
            "CYPM" = "red", 
            "CYPR" = "pink",
            "Unassigned" = NA)

stacked_barplot <- ggplot(data_long, aes(x = ID, y = Count, fill = CYP)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  scale_fill_manual(values = colors) +
  coord_flip() +
  theme(axis.text.x = element_blank(), 
        axis.text.y = element_blank(),
        axis.title.x = element_blank(), 
        axis.title.y = element_blank())

tree_plot <- ggtree(tree) + 
  #geom_tiplab(align = TRUE, linesize = 0.2, offset = 0.2) +
  #theme(plot.margin = margin(1, 1, 1, 20)) +
  geom_tiplab(hjust = -0.2)

combined_plot <- plot_grid(tree_plot + xlim_tree(14), stacked_barplot, ncol = 2, rel_widths = c(1, 1.2))

print(combined_plot)
