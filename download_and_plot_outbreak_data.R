library(outbreakinfo)
library(stringr) 
library(ggplot2)

make_sure_dir_exists <- function(dir_path) {
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
}

download_mutation_profiles <- function(lineages, output_dir){
  make_sure_dir_exists(output_dir)
  
  downloaded_paths = c()
  
  for (lineage in lineages) {
    mutations = getMutationsByLineage(pangolin_lineage=lineage , frequency=0.75, logInfo = FALSE)
    
    # filter for Spike:
    mutations_s <- subset(mutations, gene=="S")
    # save to file
    filepath = paste(paste(output_dir,"/mutation", sep=""), lineage, ".txt", sep="_")
    write.table(mutations_s, file=filepath)
    downloaded_paths = c(downloaded_paths, filepath)
  }
  return(downloaded_paths)
}

plot_mutation_profiles <- function(muation_profile_paths, out_dir){
  make_sure_dir_exists(out_dir)
  for (profile_path in mutation_profile_paths){
    file_basename <- basename(profile_path)
    file_basename_no_ext = str_sub(tools::file_path_sans_ext(file_basename), end=-2)
    output_filename = paste("heatmap_", file_basename_no_ext, ".png", sep="")
    output_filepath= paste(out_dir, output_filename, sep="/")
    # Plot the mutations as a heatmap and save it
    print(paste("Saving plot at: ", output_filepath))
    mutation = read.table(profile_path)
    this_plot <- plotMutationHeatmap(mutation, title = paste("S-gene mutations in lineage", file_basename, sep=" "))
    ggplot2::ggsave(filename = output_filepath, plot = this_plot, width = 8, height = 6, dpi = 300)
  }
}

#set wd
current_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(current_dir)

# get mutations for JN.1, JN.2, JN.3, KP.3, XBB.1.5:
lineages = c(
  "JN.1",
  "JN.2",
  "JN.3",
  "KP.3",
  "XBB.1.5"
)

outbreakinfo::authenticateUser()
mutation_profile_paths = download_mutation_profiles(lineages, "./downloads")
plot_mutation_profiles(mutation_profile_paths, "plots")
