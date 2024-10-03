# Project 5 Cross-Immunization 
Vincent Musch </br>
Mathias Wajnberg

### This repository corresponds to the projects of the 2024 datascience practical module https://github.com/rki-mf1/2024-SC2-Data-Science

## Repository structure overview
### ./downloads
Mutation profiles downloaded from GISAID using R. The subdirectory "stripped" holds the data in VASIL compatible format.
### ./plots
Various mutation profile and lineage plots, generated from GISAID data 
using [download_and_plot_outbreak_data.R](src/download_and_plot_outbreak_data.R).

### ./pymol_dropped
Contains data and code that we wrote for our PyMol approach, before we decided to drop the topic due to time 
constraints and lack of expertise.

### ./src
Holds all of our R and Python Scripts to perform data download from GISAID and the plotting of those and the data 
generated from VASIL. Hereby, the R script handles everything GISAID related, whereas the Python scripts work with 
the VASIL results.

### ./vasil_output
Vasil results for different lineage-pairs as .svg, .csv and .pdf overview.
Subfolder "merged" holds the summarized results for our tasks' target lineages.

## Prerequisites
### The R packages in use are 
* outbreakinfo
* stringr
* ggplot2
* RColorBrewer

Furthermore a user account at [gisaid.org](gisaid.org) is needed to download mutation profiles and prevalence data.

### The python packages in use
* can be derived and installed via the ['requirements.txt'](requirements.txt)
