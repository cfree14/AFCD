
# Clear workspace
rm(list = ls())

# Setup
################################################################################

# Packages
library(tidyverse)

# Directories
indir <- "/Users/cfree/Dropbox/Chris/UCSB/projects/nutrition/AFCD/raw/"
outdir <- "/Users/cfree/Dropbox/Chris/UCSB/projects/nutrition/AFCD/processed"

# Resources
# GitHub: https://github.com/zachkoehn/aquatic_foods_nutrient_database
# DataVerse: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/KI0NYM
# Nature: https://www.nature.com/articles/s41586-021-03917-1?proof=t%2Btarget%3D#data-availability

# Read data
data_orig <- read.csv(file.path(indir, "20210914_AFCD.csv"))

# Read reference key
ref_fct_orig <- readxl::read_excel(file.path(indir, "afcd_references.xlsx"), sheet="fct_references")
ref_peer_orig <- readxl::read_excel(file.path(indir, "afcd_references.xlsx"), sheet="peer_review_references")

# Read column key
col_key_orig <- readxl::read_excel(file.path(indir, "afcd_variable_codex.xlsx"))

# Lots of work to do here:
# 3) Fix up species taxonomy and build species key
# 4) Add common names
# 5) Fix up country codes and add countries
# 6) Fix up all the nutrient names, units, descriptions - maybe provide nutrient key


# Build reference key
################################################################################

# Format FCT reference key
ref_fct <- ref_fct_orig %>% 
  # Rename
  janitor::clean_names() %>% 
  rename(study_id=study_id_number, 
         doi=link_to_dataset,
         database=nutrient_database,
         units=nutrients_per) %>% 
  # Add study type
  mutate(study_type="Food Composition Table (FCT)") %>% 
  # Arrange
  select(study_type, study_id, citation, doi, database, units, everything()) %>% 
  # Remove useless columns
  select(-c(notes, added_by, already_included, format))

# Inspect
colnames(ref_fct)
table(ref_fct$units)

# Format peer reviewed reference key
ref_peer <- ref_peer_orig %>% 
  # Rename
  janitor::clean_names() %>% 
  rename(study_id=study_id_number,
         doi=study_doi,
         region=study_region,
         citation=study_apa_citation) %>% 
  # Add study type
  mutate(study_type="Peer-reviewed literature") %>% 
  # Convert study id
  mutate(study_id=as.character(study_id)) %>% 
  # Arrange
  select(study_type, study_id, everything()) %>% 
  # Remove useless columns
  select(-x5)

# Inspect
colnames(ref_peer)
table(ref_peer$region)

# Merge reference key
ref_key <- bind_rows(ref_peer, ref_fct) %>% 
  arrange(study_type, study_id) %>% 
  select(study_type, study_id, citation, everything())

# Inspect
freeR::complete(ref_key)

# Export
saveRDS(ref_key, file.path(outdir, "AFCD_reference_key.Rds"))


# Nutrient key
################################################################################

# Build column key
col_key <- col_key_orig %>% 
  # Rename
  janitor::clean_names() %>% 
  rename(col_id=x1, col_name=afcd_variable_name, units=unit, fao_code=fao_tagname_if_applicable)

# Build nutrient key
nutr_key <- col_key %>% 
  # Simplify
  select(-col_id) %>% 
  # Reduce to nutrients
  filter(units!="none" | is.na(units)) %>% 
  # Rename
  rename(nutrient_orig=col_name) %>% 
  # Format
  mutate(nutrient_orig=tolower(nutrient_orig)) %>% 
  # Add nutrient column 
  mutate(nutrient=stringr::str_to_title(nutrient_orig) %>% gsub("_", " ", .)) %>% 
  # Arrange
  select(nutrient_orig, nutrient, units, fao_code, description)


  


# Format data
################################################################################

# Format data
data1 <- data_orig %>% 
  # Rename columns
  janitor::clean_names() %>% 
  rename(sciname=taxa_name,
         food_part=parts_of_food, 
         food_prep=preparation_of_food,
         prod_catg=production_category,
         edible_prop=edible_portion_coefficient,
         study_id=study_id_number,
         iso3=country_iso3,
         fao3=fao_3a_code, 
         fct_code_orig=original_fct_food_code,
         food_name=food_name_in_english,
         food_name_orig=food_name_in_original_language) %>% 
  # Arrange
  select(sciname:food_name_orig, notes, everything()) %>% 
  # Gather
  gather(key="nutrient", value="value", 22:ncol(.)) %>% 
  # Reduce to rows with data
  filter(!is.na(value))

# Inspect countries
contry_key <- data1 %>% 
  # Unique ISOs
  select(iso3) %>% 
  unique() %>% 
  # Add country
  mutate(country=countrycode::countrycode(iso3, "iso3c", "country.name")) %>% 
  # Sort
  arrange(iso3)

# Format data some more
data2 <- data1 %>% 
  # Format scientific name
  mutate(sciname=stringr::str_to_sentence(sciname), 
         sciname=stringr::str_trim(sciname)) %>% 
  # Format other taxonomic info
  mutate(across(.cols=kingdom:genus, .fns=stringr::str_to_title),
         across(.cols=kingdom:genus, .fns=stringr::str_trim)) %>% 
  # Format taxa database
  mutate(taxa_db=stringr::str_to_upper(taxa_db)) %>% 
  # Format food parts
  mutate(food_part=gsub("_", " ",  food_part)) %>% 
  # Format food preparation
  mutate(food_prep=gsub("_", " ",  food_prep)) %>% 
  # Format production category
  mutate(prod_catg=gsub("_", " ",  prod_catg)) %>% 
  # Add nutrient info
  left_join(nutr_key, by=c("nutrient"="nutrient_orig")) %>% 
  # Arrange
  select(sciname:taxa_db, 
         study_id, peer_review, iso3, fao3,
         prod_catg, food_part, food_prep, food_name, food_name_orig, notes,
         nutrient, description, fao_name, units, value, everything())
  
  
# Inspect
str(data2)
freeR::complete(data2)

# Inspect nutrients
nutr_key_check <- data2 %>% 
  select(nutrient, units, description) %>% 
  unique()

# Inspect taxa
table(data2$kingdom)
sort(unique(data2$phylum))
sort(unique(data2$order))  
sort(unique(data2$family))  
sort(unique(data2$genus)) 
table(data2$taxa_db)

# Inspect food parts
table(data2$food_part)
table(data2$food_prep)
table(data2$prod_catg)

# Inspect edible proportions (should be 0-1)
range(data2$edible_prop, na.rm=T)

# Inspect study characteristics
sort(unique(data2$study_id))
table(data2$peer_review)

# Study ids not in key
data2$study_id[!data2$study_id %in% ref_key$study_id] %>% unique() %>% sort()

# Study ids in key not in data
ref_key$study_id[!ref_key$study_id %in% data2$study_id] %>% unique() %>% sort()

# Inspect foods
sort(unique(data2$fct_code_orig))
sort(unique(data2$food_name))
sort(unique(data2$food_name_orig))


# Species key
################################################################################

# Species key
spp_key <- data2 %>% 
  # Unique species
  group_by(sciname, taxa_id) %>% 
  summarize(n=n()) %>% 
  ungroup() %>% 
  # Recode species
  rename(sciname_orig=sciname) %>% 
  mutate(sciname=)

# Check names
wrong_names1 <- freeR::check_names(spp_key$sciname)
wrong_names2 <- wrong_names1[!grepl("spp|sp.", wrong_names1) & wrong_names1!=""]
suggested_names <- freeR::suggest_names(wrong_names2[1:10])



prep_suggested_names <- function(suggest_list){}


# Export data
################################################################################

# Export data
saveRDS(data2, file=file.path(outdir, "20210914_AFCD_cleaned.Rds"))







