
# Clear workspace
rm(list = ls())

# Setup
################################################################################

# Packages
library(tidyverse)

# Directories
indir <- "data-raw/raw"
outdir <- "data-raw/processed"

# Read data
afcd <- readRDS(file=file.path(outdir, "AFCD_data.Rds"))
afcd_refs <- readRDS(file=file.path(outdir, "AFCD_reference_key.Rds"))
afcd_nutrients <- readRDS(file=file.path(outdir, "AFCD_nutrient_key.Rds"))


# Export data
usethis::use_data(afcd, overwrite = T)
usethis::use_data(afcd_refs, overwrite = T)
usethis::use_data(afcd_nutrients, overwrite = T)
