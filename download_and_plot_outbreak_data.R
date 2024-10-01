library(outbreakinfo)
library(stringr) 
library(ggplot2)

make_sure_dir_exists <- function(dir_path) {
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
}

extract_mutation_only <- function(mutation_table){
  # Check if the "mutation" column exists
  if (!"mutation" %in% colnames(mutation_table)) {
    stop("The column 'mutation' is not found in the DataFrame.")
  }
  
  # Strip "s:" from the beginning of each string in the "mutation" column
  mutation_table$mutation_count <- gsub("^s:", "", mutation_table$mutation)
  
  return(mutation_table$mutation_count)
}

download_mutation_profiles <- function(lineages, output_dir){
  make_sure_dir_exists(output_dir)
  stripped_dir = paste(output_dir,"/stripped", sep="")
  make_sure_dir_exists(stripped_dir)
  
  downloaded_paths_raw = c()
  
  for (lineage in lineages) {
    mutations = getMutationsByLineage(pangolin_lineage=lineage , frequency=0.75,
                                      logInfo = FALSE)
    
    # filter for Spike:
    mutations_s <- subset(mutations, gene=="S")
    mutations_s_only_mutation <- extract_mutation_only(mutations_s)
    # save to files
    filepath_raw = paste(paste(output_dir,"/mutation", sep=""), 
                         lineage, ".txt", sep="_")
    filepath_stripped = paste(paste(stripped_dir,"/mutation", sep=""), 
                              lineage, "_stripped.txt", sep="_")
    write.table(mutations_s, file=filepath_raw)
    write.table(mutations_s_only_mutation, file=filepath_stripped, 
                row.names = FALSE, col.names = FALSE, quote=FALSE)
    downloaded_paths_raw = c(downloaded_paths_raw, filepath_raw)
  }
  return(downloaded_paths_raw) # for plotting function
}

plot_mutation_profiles <- function(muation_profile_paths, out_dir){
  make_sure_dir_exists(out_dir)
  for (profile_path in mutation_profile_paths){
    file_basename <- basename(profile_path)
    file_basename_no_ext = str_sub(tools::file_path_sans_ext(file_basename), 
                                   end=-2)
    output_filename = paste("heatmap_", file_basename_no_ext, ".png", sep="")
    output_filepath= paste(out_dir, output_filename, sep="/")
    # Plot the mutations as a heatmap and save it
    print(paste("Saving plot at: ", output_filepath))
    mutation = read.table(profile_path)
    this_plot <- plotMutationHeatmap(mutation, 
                          title = paste("S-gene mutations in lineage",
                          gsub("mutation_", "",file_basename_no_ext), sep=" "))
    ggplot2::ggsave(filename = output_filepath, plot = this_plot, 
                    width = 10, height = 6, dpi = 300)
  }
}

plot_muttions_by_lineages <- function(lineages, output_path){
  make_sure_dir_exists(output_path)
  mutations = getMutationsByLineage(lineages)
  this_plot <- plotMutationHeatmap(mutations,
               title = "Mutations with at least 75% prevalence in Variants of Concern", 
               lightBorders = FALSE)
  filename = paste("mutation_diffs", toString(lineages),".png", sep="_")
  output_filepath = paste(output_path, filename, sep="/")
  ggplot2::ggsave(filename = output_filepath, plot = this_plot, 
                  width = 10, height = 6, dpi = 300)
  
}

plot_prevalences <- function(lineages, output_path, location="Germany"){
  make_sure_dir_exists(output_path)
  prevalence_data = c()
  for (lineage in lineages){
    prevalence = getPrevalence(lineage, location)
    prevalence_data = c(prevalence_data, prevalence)
    
    this_plot <- plotPrevalenceOverTime(prevalence, title=paste(lineage,"prevalence over time in Germany."))
    filename = paste(paste("prevalence_lineage", lineage, sep="_"), ".png")
    output_filepath = paste(output_path,filename,sep="/")
    ggplot2::ggsave(filename = output_filepath, plot = this_plot, 
                    width = 10, height = 6, dpi = 300)
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
plot_muttions_by_lineages(lineages, "plots")
plot_prevalences(lineages, "plots")

