#login
library(outbreakinfo)
outbreakinfo::authenticateUser()

# get mutations for JN.1, JN.2, JN.3, KP.3, XBB.1.5:
lineages = c(
  "JN.1",
  "JN.2",
  "JN.3",
  "KP.3",
  "XBB.1.5"
)

for (lineage in lineages) {
  mutations = getMutationsByLineage(pangolin_lineage=lineage , frequency=0.75, logInfo = FALSE)
  
  # filter for Spike:
  mutations_s <- subset(mutations, gene=="S")
  write.table(mutations_s, file=c("mutation_", lineage, ".txt", sep="\n"))
  
  # Plot the mutations as a heatmap and save it
  png(filename=c("plots/heatmap_mutation_", lineage, ".png"))
  plotMutationHeatmap(mutations_s, title = "S-gene mutations in lineages")
  dev.off()
}