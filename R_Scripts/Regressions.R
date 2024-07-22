library(ggplot2)

P450.clan <- read.delim("C:/Users/utente/OneDrive/Desktop/P450.clan.count")
P450.clan$Sum <- rowSums(P450.clan[, 3:7])
print(P450.clan)

##SINGLE REGRESSION
ggplot(P450.clan, aes(x = CYPM, y = Sum)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "steelblue") +
  labs(title = "Regression Plot",
       x = "CYP3",
       y = "CYPome") +
  theme_minimal()

##MULTIPLE REGRESSION
library(tidyr)

df_long <- P450.clan %>%
  pivot_longer(cols = CYP2:CYPR, names_to = "Variable", values_to = "Value")

# Create the plot
ggplot(df_long, aes(x = Value, y = Sum, color = Variable)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~Variable) +
  labs(title = "Regression Plot",
       x = "CYP", y = "Sum") +
  theme_minimal()









