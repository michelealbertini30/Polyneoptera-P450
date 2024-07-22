library(phytools)
library(geiger)
library(phangorn)
library(ggplot2)

tree <- read.tree("P450_events.newick")

internal_node_ids <- (length(tree$tip.label) + 1):(length(tree$tip.label) + tree$Nnode)

brlength1 = c()
brlength2 = c()
event = c()
delta_vector = c()

for (i in internal_node_ids) {
  
  ch <- Children(tree, i)
  ln1 <- tree$edge.length[ch[1]]
  brlength1[i-1276] <- ln1 #vettore 
  ln2 <- tree$edge.length[ch[2]]
  brlength2[i-1276] <- ln2
  
  delta <- abs(ln2-ln1)
  delta_vector[i-1276] <- delta
  
  
  ev <- tree$node.label[i-1276]
  event[i-1276] <- ev
  
}

df <- data.frame(brlength1,brlength2,event,delta_vector)

ggplot(df, aes(x=event, y=delta_vector, fill=event)) + 
  geom_violin() + theme_minimal()


