library(shiny)
library(shinythemes)
library(shinyWidgets)
library(tidyverse)
library(plotly)
library(uwot)
library(randomForest)
library(nabor)
library(DT)
library(markdown)
library(knitr)
library(shinycssloaders)

source('www/modal_funs.R')

# get data:
minerals_file <- readRDS('www/Mineral_Database.rds')
minerals_umap <- readRDS('www/3Dtsne.rds')
clusts <- readRDS('www/clusts.rds')


# get names
minerals_names <- minerals_file$MineralName
chem_names <- minerals_file$ChemFormula

# convert the mineral values to numeric and replace NA with 0
minerals <-
  minerals_file %>% 
  dplyr::select(-c(MineralName, ChemFormula, MolWeight, URL, Iteration, CHECK)) %>% 
  mutate_all(function(x) as.numeric(x))

minerals[is.na(minerals)] <- 0
  
# names of minerals:
element_names <- sort(colnames(minerals))

# bind back all the data into one data.frame
df <-
  bind_cols(
    data.frame(Mineral = minerals_names,
               ChemFormula = chem_names),
    minerals_umap %>% as.data.frame(),
    data.frame(clusts = clusts),
    minerals
  )

# rename a few columns for cleanliness
names(df)[1:6] <- c('Mineral', 'ChemFormula', 'x', 'y', 'z', 'Cluster')



# knit help files
# knit('www/introduction.Rmd', output = 'www/introduction.md')
knit('www/whatIsMICA.Rmd', output = 'www/whatIsMICA.md')
knit('www/howUseMICA.Rmd', output = 'www/howUseMICA.md')