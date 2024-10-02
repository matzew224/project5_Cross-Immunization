library(outbreakinfo)
library(stringr) 
library(ggplot2)
library(RColorBrewer)

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
    filepath_raw = paste(paste(output_dir,"/mutation_", sep=""), 
                         lineage, ".txt", sep="")
    filepath_stripped = paste(paste(stripped_dir,"/mutation_", sep=""), 
                              lineage, "_stripped.txt", sep="")
    write.table(mutations_s, file=filepath_raw)
    write.table(mutations_s_only_mutation, file=filepath_stripped, 
                row.names = FALSE, col.names = FALSE, quote=FALSE)
    downloaded_paths_raw = c(downloaded_paths_raw, filepath_raw)
  }
  return(downloaded_paths_raw) # for plotting function
}

plot_mutation_profiles <- function(mutation_profile_paths, out_dir){
  make_sure_dir_exists(out_dir)
  for (profile_path in mutation_profile_paths){
    file_basename <- basename(profile_path)
    file_basename_no_ext = str_sub(tools::file_path_sans_ext(file_basename), 
                                   end=-3)
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

plot_mutations_by_lineages <- function(lineages, output_path){
  # multiple lineages in one plot
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

concat_lists <- function(list1, list2) {  
  
  keys <- unique(c(names(list1), names(list2)))
  map2(list1[keys], list2[keys], c) %>% 
    set_names(keys)  
  
}

plot_prevalences <- function(lineages, output_path, location="Germany"){
  make_sure_dir_exists(output_path)
  
  # uncomment for one plot per lineage
  # TODO: tidy up
  # for (lineage in lineages){
  #   prevalence = getPrevalence(lineage, location)
  #   
  #   this_plot <- plotPrevalenceOverTime(prevalence, title=paste(lineage,"prevalence over time in Germany."))
  #   filename = paste(paste("prevalence_lineage", lineage, sep="_"), ".png")
  #   output_filepath = paste(output_path,filename,sep="/")
  #   ggplot2::ggsave(filename = output_filepath, plot = this_plot, 
  #                   width = 10, height = 6, dpi = 300)
  # }
  
  combined_prevalence_data <- getPrevalence(pangolin_lineage = lineages, location = location)
  combined_plot <- plotPrevalenceOverTime(combined_prevalence_data, title = paste("Prevelance over time for lineages: ", toString(lineages)))
  # palette="Set3"
  # palette="Accent"
  palette="Dark2"
  

  combined_plot <- combined_plot + scale_color_brewer(palette=palette) + scale_fill_brewer(palette=palette)
  
  
  filename = paste("prevalence", gsub(",", "_", toString(lineages)), sep="_")
  filename = gsub("\\.", "-", filename)
  filename = gsub(" ", "", filename)
  filename = paste(filename, ".svg", sep="")
  
  output_filepath = paste(output_path,filename,sep="/")
  print(paste("Saving plot to :", output_filepath))
  ggplot2::ggsave(filename = output_filepath, plot = combined_plot, 
                  width = 15.5, height = 6, dpi = 300)
    

}



## Run from here on

#set wd
current_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(current_dir)

# # get mutations for JN.1, JN.2, JN.3, KP.3, XBB.1.5:
# lineages = c(
#   "JN.1",
#   "JN.2",
#   "JN.3",
#   "KP.3",
#   "XBB.1.5"
# )

# get mutations for JN.1, JN.2, JN.3:
lineages = c(
  "JN.1",
  "JN.2",
  "JN.3",
)

# # get mutations for XBB.1.5 and sub lineages:
# #TODO: truncate in this lineage to jan 2024
# lineages = c(
#   "XBB.1.5",
#   # "XBB.1.5.70",
#   "XBB.1.16",
#   "EG.5"
# )

# get mutations for KP.2.3, KP.3, KP.4.1:
#TODO: truncate in this lineage to jan 2024
# lineages = c(
#   "KP.2",
#   "KP.3",
#   "KP.4.1"
# )


outbreakinfo::authenticateUser()
output_dir="plots"
mutation_profile_paths = download_mutation_profiles(lineages, "./downloads")
plot_mutation_profiles(mutation_profile_paths, output_dir)
plot_mutations_by_lineages(lineages, output_dir)
plot_prevalences(lineages, output_dir)

