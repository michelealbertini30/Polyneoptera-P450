library(ggplot2)
library(tidyr)
library(dplyr)

cypome_data <- read.delim("CYPome.tsv", header = TRUE, stringsAsFactors = FALSE)
lifetraits_data <- read.delim("LifeTraits.tsv", header = TRUE, stringsAsFactors = FALSE)

lifetraits_data <- lifetraits_data %>%
  separate_rows(Habitat, sep = ", ")

merged_data <- merge(cypome_data, lifetraits_data, by = "ID")

#SCATTER PLOT
plot_cyp_vs_trait <- function(cyp_clade, trait) {
  ggplot(merged_data, aes_string(x = trait, y = cyp_clade)) +
    geom_point() +
    geom_jitter(width = 0.2, height = 0, color = "blue", alpha = 0.6) +
    labs(title = paste("Correlation between", cyp_clade, "and", trait),
         x = trait,
         y = paste(cyp_clade, "count")) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

#BOXPLOT
plot_cyp_vs_trait <- function(cyp_clade, trait) {
  ggplot(merged_data, aes_string(x = trait, y = cyp_clade)) +
    geom_boxplot(fill = "lightblue", color = "darkblue", outlier.color = "red") +
    geom_jitter(width = 0.2, height = 0, color = "black", alpha = 0.6) +
    labs(title = paste("Distribution of", cyp_clade, "across", trait),
         x = trait,
         y = paste(cyp_clade, "count")) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

plot_cyp_vs_trait("CYP3", "Diet")

#Tests Significance of a distribution in general
kruskal_test <- kruskal.test(CYP3 ~ Diet, data = merged_data)
print(kruskal_test)

#Tests Significance of a variable in a distribution
merged_data$Herbivorous <- ifelse(merged_data$Diet == "Herbivorous", "Herbivorous", "Non-Herbivorous")
wilcox_test <- wilcox.test(CYP3 ~ Herbivorous, data = merged_data)
print(wilcox_test)

merged_data$Dry <- ifelse(merged_data$Humidity == "Dry", "Dry", "Humid")
wilcox_test <- wilcox.test(CYP4 ~ Dry, data = merged_data)
print(wilcox_test)


library(coin)
merged_data$Herbivorous <- as.factor(merged_data$Herbivorous)
perm_test <- wilcox_test(CYP3 ~ Herbivorous, data = merged_data, distribution = "approximate")
print(perm_test)


# To Loop and create all plots at the same time
#cyp_clades <- colnames(cypome_data)[-1]  # All columns except 'ID' in CYPome.tsv
#life_traits <- colnames(lifetraits_data)[-1]  # All columns except 'ID' in LifeTraits.tsv

#for (cyp in cyp_clades) {
#  for (trait in life_traits) {
#    plot_file_name <- paste0("plot_", cyp, "_vs_", trait, ".png")
#    png(plot_file_name, width = 800, height = 600)
#    print(plot_cyp_vs_trait(cyp, trait))
#    dev.off()
#  }
#}

