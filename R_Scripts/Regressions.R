library(ggplot2)

P450.clan <- read.delim("C:/Users/utente/OneDrive/Desktop/CYPome.tsv")
P450.clan$Sum <- rowSums(P450.clan[, 2:6])
print(P450.clan)

##SINGLE REGRESSION
ggplot(P450.clan, aes(x = CYP2, y = Sum)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "steelblue") +
  labs(title = "Regression Plot",
       x = "CYP2",
       y = "CYPome") +
  theme_minimal()

##MULTIPLE REGRESSION
library(tidyr)

df_long <- P450.clan %>%
  pivot_longer(cols = CYP2:CYPM, names_to = "Variable", values_to = "Value")

# Create the plot
ggplot(df_long, aes(x = Value, y = Sum, color = Variable)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~Variable) +
  labs(title = "Regression Plot",
       x = "CYP", y = "Sum") +
  theme_minimal()

##MULTIPLE ON THE SAME PLOT
library(ggplot2)
library(tidyr)
library(dplyr)

color = c("red", "green", "steelblue", "yellow")

ggplot(df_long, aes(x = Value, y = Sum, color = Variable)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Regression Plot",
       x = "CYP", y = "Sum") +
  theme_minimal() +
  scale_color_brewer(palette = "Set1")








