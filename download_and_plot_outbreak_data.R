library(outbreakinfo)
library(stringr) 
library(ggplot2)
library(RColorBrewer)

outbreakinfo::authenticateUser()
output_dir="plots"

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

my_plotPrevalenceOverTime <- function(df, lineages, colorVar = "lineage", title = "Prevalence over time", 
          labelDictionary = NULL){
  # function similar to the one from outbreak package but with legend ordered according to lineage vector
  # and without geom_ribbon showing confidence intervals
  
  # order legend
  df[[colorVar]] <- factor(df[[colorVar]], levels = lineages)
  if (!is.null(df) && nrow(df) > 0) {
    if (!is.null(labelDictionary)) {
      df = df %>% mutate(lineage = ifelse(is.na(unname(labelDictionary[lineage])), 
                                          lineage, unname(labelDictionary[lineage])))
    }
    p <- ggplot(df, aes(x = date, y = proportion, colour = .data[[colorVar]], 
                        fill = .data[[colorVar]], group = .data[[colorVar]])) + 
      geom_line(size = 1.25) + 
      scale_x_date(date_labels = "%b %Y", expand = c(0, 0)) + 
      scale_y_continuous(labels = scales::percent, expand = c(0, 0)) + 
      theme_minimal() + 
      labs(caption = "Enabled by data from GISAID (https://gisaid.org/)")
    theme(legend.position = "bottom", axis.title = element_blank(), 
          plot.caption = element_text(size = 18))
    
    if (!is.null(title)) {
      p <- p + ggtitle(title)
    }
    return(p)
  }
  else {
    warning("Dataframe is empty.")
  }
}

style_and_save_plot <- function(plot, outpath, lineages, date_breaks=NA){
  # palette="Set3"
  # palette="Accent"
  palette="Dark2"
  
  plot <- plot + scale_color_brewer(palette=palette) + scale_fill_brewer(palette=palette)
  
  # date ticks
  if(is.na(date_breaks)){
    date_breaks="2 months"
  }
  else if (date_breaks!="default") {
    # use what is given as argument
    plot <- plot + scale_x_date(date_breaks = date_breaks, date_labels = "%b %Y")
  }
  
  
  print(paste("Saving plot to :", outpath))
  ggplot2::ggsave(filename = outpath, plot = plot, 
                  width = 15.5, height = 6, dpi = 500)
  
}

plot_prevalences <- function(lineages, output_path, location="Germany", mode="lineages", merging="merged", date_breaks=NA){
  make_sure_dir_exists(output_path)
  if(merging=="single" || merging=="both"){
    for (lineage in lineages){
      if (mode=="lineages"){
        prevalence <- getPrevalence(pangolin_lineage = lineage, location = location)
      }
      else {
        # specific mutations ond not lineages
        prevalence <- getPrevalence(mutations = lineage, location=location)
      }
    
      this_plot <- my_plotPrevalenceOverTime(prevalence, title=paste(lineage,"prevalence over time in Germany."))
      filename = paste(paste(paste("prevalence_", mode, sep=""), lineage, sep="_"), ".png")
      output_filepath = paste(output_path,filename,sep="/")
      print(paste("Saving plot to :", output_filepath))
      ggplot2::ggsave(filename = output_filepath, plot = this_plot,
                      width = 10, height = 6, dpi = 300)
    }
  }
  
  else if (merging=="merged" || merging=="both"){
    if (mode=="lineages"){
      combined_prevalence_data <- getPrevalence(pangolin_lineage = lineages, location = location)
    }
    else {
      # mutations
      combined_prevalence_data <- getPrevalence(mutations = lineages, location=location)
    }
    combined_plot <- my_plotPrevalenceOverTime(combined_prevalence_data, lineages, title = paste(paste("Prevelance over time for: ", mode, sep=""), toString(lineages)))
    
    filename = paste("prevalence", gsub(",", "_", toString(lineages)), sep="_")
    # filename = gsub("\\.", "-", filename)
    filename = gsub(" ", "", filename)
    filename = paste(filename, ".png", sep="")
    output_filepath = paste(output_path,filename,sep="/")
    
    style_and_save_plot(combined_plot, output_filepath, lineages, date_breaks=date_breaks)
    
  }
    

}


#set wd
current_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(current_dir)

# here come some lineage sets of interest, followed by function call for 
# plotting of respective prevalence

# # get mutations for JN.1, JN.2, JN.3:
lineages = c(
  "JN.1",
  "JN.2",
  "JN.3"
)
plot_prevalences(lineages, output_dir, date_breaks="3 months")

# # get mutations for XBB.1.5 and sub lineages:
# #TODO: truncate in this lineage to jan 2024
lineages = c(
  "XBB.1.5",
  "XBB.1.5.70",
  "XBB.1.9.2",
  "XBB.1.16",
  "XBB.1.16.24",
  "EG.5"
)
plot_prevalences(lineages, output_dir, date_breaks="3 months")

# get mutations for KP.2.3, KP.3, KP.4.1:
lineages = c(
  "KP.2",
  "KP.3",
  "KP.4.1"
)
plot_prevalences(lineages, output_dir, date_breaks="3 months")

# get targets for booster vaccines
lineages = c(
  "BA.1",
  "BA.4",
  "BA.5",
  "KP.2"
)
plot_prevalences(lineages, output_dir, date_breaks="3 months")

# get lineages that first got called Alpha, Beta, Gamma, Delta, Omicron
lineages = c(
  "B.1.1.7", #Alpha
  "B.1.351", #Beta
  "P.1", #Gama
  "B.1.617.2", #Delta begin
  "BA.1", # omicron vaccine
  "BA.4", #stil omicron
  "XBB.1.5", # still omicron
  "KP.2" #omicron today
)
plot_prevalences(lineages, output_dir, date_breaks="3 months")

# get Omicron lineages
lineages = c(
  "B.1.1.529", #omicron begin
  "BA.1", # omicron vaccine
  "BA.4", #stil omicron
  "BA.5",
  "XBB.1.5", # still omicron
  "KP.2",
  "KP.3" #omicron today
)
plot_prevalences(lineages, output_dir, date_breaks="3 months")

# run on specific mutations rather than lineages
# currently only working for plot_prevalences() with mode="mutations"
mutations = c(
  "S:E484K",
  "S:F486P",
  "S:R346T"
)
plot_prevalences(mutations, output_dir, mode="mutations", merging="both")

# # get mutations for JN.1, JN.2, JN.3, KP.3, XBB.1.5:
lineages = c(
  "XBB.1.5",
  "JN.1",
  "JN.2",
  "JN.3",
  "KP.3"
)
plot_prevalences(lineages, output_dir, date_breaks="3 months")



# mutation_profile_paths = download_mutation_profiles(lineages, "./downloads")
# plot_mutation_profiles(mutation_profile_paths, output_dir)
# plot_mutations_by_lineages(lineages, output_dir)

# plot_prevalences(lineages, output_dir)

