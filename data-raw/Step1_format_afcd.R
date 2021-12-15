
# Clear workspace
rm(list = ls())

# Setup
################################################################################

# Packages
library(tidyverse)

# Directories
indir <- "data-raw/raw"
outdir <- "data-raw/processed"

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


# Step 1. Rename columns and go from wide to long
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
         food_id=food_item_id,
         food_name=food_name_in_english,
         food_name_orig=food_name_in_original_language) %>%
  # Arrange
  select(sciname:food_name_orig, food_id, notes, everything()) %>%
  # Gather nutrients (maintain capitalization)
  gather(key="nutrient_orig", value="value", 23:ncol(.)) %>%
  mutate(nutrient_orig=stringr::str_to_sentence(nutrient_orig)) %>%
  # Reduce to rows with data
  filter(!is.na(value))


# Step 2. Build nutrient key
################################################################################

# Build column key
col_key <- col_key_orig %>%
  # Rename
  janitor::clean_names() %>%
  rename(col_id=x1, col_name=afcd_variable_name, units=unit, fao_code=fao_tagname_if_applicable)

# Build nutrient key
nutr_col_key <- col_key %>%
  # Simplify
  select(-col_id) %>%
  # Reduce to nutrients
  filter(units!="none" | is.na(units)) %>%
  # Rename
  rename(nutrient_orig=col_name) %>%
  # Arrange
  select(nutrient_orig, units, fao_code, description) %>%
  unique()

# Identify nutrients in data
nutr_key_orig <- data1 %>%
  # Identify nutrients in dataset
  select(nutrient_orig) %>%
  unique() %>%
  arrange(nutrient_orig) %>%
  # Add known meta-data from column key
  left_join(nutr_col_key, by="nutrient_orig") %>%
  # Format nutrient name
  mutate(nutrient=nutrient_orig %>% gsub("_", " ", .)) %>%
  # Arrange
  select(nutrient_orig, nutrient, units, description, everything())

# Export for formatting outside R
write.csv(nutr_key_orig, file.path(indir, "AFCD_nutrient_key_work.csv"), row.names = F)

# Read formatted key
nutr_key_use <- readxl::read_excel(file.path(indir, "AFCD_nutrient_key_work.xlsx"))


# Step 3. Format data
################################################################################

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
  # Format I30
  # BNG = may be West Bengal
  # GRB
  mutate(iso3=stringr::str_trim(iso3),
         iso3=ifelse(iso3=="", "Not provided", iso3),
         iso3=recode(iso3,
                     "SAu"="SAU",
                     "BNG"="IND", # West Bengal which is part of India - study 1407
                     "GRB"="GBR", # study 789 mis-recorded
                     "KHG"="ITA", # study 338 mis-recorded
                     "MYL"="MYS", # study 1438 mis-recorded
                     "PNDB"="Pacific Region",
                     "smiling_cambodia"="KHM",
                     "smiling_indonesia"="IDN",
                     "smiling_laos"="LAO",
                     "smiling_thailand"="THA",
                     "smiling_vietnam"="VNM",
                     "unknown (Caspian Sea)"="Caspian Sea",
                     "unknown"="Unknown",
                     "POL/ AUS"="POL, AUS",
                     "FAO.biodiv3"="FAO Biodiv 3",
                     "FAO.infoods.ufish1"="FAO Infoods Ufish",
                     "FAO.infoods.west.africa"="FAO West Africa",
                     "FAO.latinfoods"="FAO Latin America")) %>%
  # Add nutrients
  left_join(nutr_key_use %>% select(nutrient_orig, nutrient, description, units), by=c("nutrient_orig")) %>%
  # Arrange
  select(sciname:taxa_db,
         study_id, peer_review, iso3, fao3,
         prod_catg, food_part, food_prep, food_name, food_name_orig, fct_code_orig, food_id, edible_prop, notes,
         nutrient_orig, nutrient, description, units, value, everything())


# Step 4. Inspect data
################################################################################

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


# Inspect countries
country_key <- data2 %>%
  # Unique ISOs
  select(iso3) %>%
  unique() %>%
  # Add country
  mutate(country=countrycode::countrycode(iso3, "iso3c", "country.name")) %>%
  # Sort
  arrange(iso3)

# Species key
################################################################################

# Species key 1
spp_key1 <- data2 %>%
  # Unique species
  select(sciname) %>%
  unique() %>%
  # Recode species
  rename(sciname_orig=sciname) %>%
  mutate(sciname=sciname_orig) %>%
  # Delete dangling commas
  mutate(sciname=gsub(",$|_$", "", sciname)) %>%
  # Delete ugly characters
  mutate(sciname=gsub("<c2><a0>|<ca>|<c3><8d>", "", sciname)) %>%
  # Delete synonyms in brackets
  mutate(sciname=gsub("\\s*\\[[^\\)]+\\]", "", sciname)) %>%
  # Replace semicolons with commas
  mutate(sciname=gsub(';', ",", sciname)) %>%
  # Replace underscore with commas
  mutate(sciname=gsub(" _ ", ", ", sciname)) %>%
  # Add period to end of all SPPs
  mutate(sciname=gsub("spp.", "spp", sciname),
         sciname=gsub("spp", "spp.", sciname)) %>%
  # Add period to end of all trailing SPs
  mutate(sciname=gsub(" sp$", " sp.", sciname)) %>%
  # Add SPP to end of 1 word groups
  mutate(nwords=freeR::nwords(sciname)) %>%
  mutate(sciname=ifelse(nwords==1, paste(sciname, "spp."), sciname)) %>%
  select(-nwords) %>%
  # Mark species or group specific
  mutate(type=ifelse(grepl("spp.|sp.|,|/| x ", sciname), "group", "species")) %>% # x=hybrids, commas/slashes is multiple
  # Remove blank
  filter(sciname!="" & !is.na(sciname)) %>%
  # Remove dangling letters
  mutate(sciname=gsub(" a\\.", "", sciname)) %>%
  mutate(sciname=gsub(" l\\.", "", sciname)) %>%
  mutate(sciname=gsub(" b\\.", "", sciname)) %>%
  mutate(sciname=gsub(" v\\.", "", sciname)) %>%
  mutate(sciname=gsub(" c\\.", "", sciname)) %>%
  mutate(sciname=gsub(" h\\.", "", sciname)) %>%
  # Fix ones with punctuation
  mutate(sciname=recode(sciname,
                        "A. nodosum (r.)"="Ablennes nodosum",
                        "A. nodosum (s.)"="Ablennes nodosum",
                        "Amphioctopus fangsiao_"="Amphioctopus fangsiao",
                        "C. fragile"="Caelorinchus fragile",
                        "C. mosullensis"="Caelorinchus mosullensis",
                        "C. capoeta umbla"="Caelorinchus capoeta umbla",
                        "C. crucian"="Caelorinchus crucian",
                        "Cystoseira abies-marina"="Treptacantha abies-marina", # hyphen is correct
                        "Engraulis encrasicolus)"="Engraulis encrasicolus",
                        "F. vesiculosus"="Farfantepenaeus vesiculosus",
                        "G. chilensis"="Gadiculus chilensis",
                        # "Gracilaria bursa-pastoris"="", # hyphen is correct
                        # "Hydrocharis morsus-ranae"="", # hyphen is correct
                        "L. graellsii"="Labeo graellsii",
                        "L. xanthochilus"="Labeo xanthochilus",
                        "L. bohar"="Labeo bohar",
                        "M. pyrifera"="Macolor pyrifera",
                        "M. cephalus"="Macolor cephalus",
                        "Megaloancistrus aculeatus)"="Megaloancistrus aculeatus",
                        "Melcertus latisculatus (family penaeidae)"="Melicertus latisulcatus",
                        "Neomeris van -bosseae"="Neomeris vanbosseae",
                        "Neomeris van-bosseae"="Neomeris vanbosseae",
                        "O. aureus"="Oreochromis aureus",
                        "Oncorhynchus mykiss)"="Oncorhynchus mykiss",
                        "Oreochromis niloticus (juvenile)"="Oreochromis niloticus",
                        "Pangasianodon hypophthalmus (juvenile)"="Pangasianodon hypophthalmus",
                        "Paralichthys oli<ea>aceus"="Paralichthys olivaceus",
                        "Perca -uviatilis"="Perca fluviatilis",
                        "Pinirampus pinirampu)"="Pinirampus pirinampu",
                        "Pseudoplatystoma corruscans)"="Pseudoplatystoma corruscans",
                        "S. sierra"="Scomberomorus sierra",
                        "Salmo trutta m. lacustris"="Salmo trutta",
                        "Sepia o.cinalis"="Sepia officinalis",
                        "Skeletonema marinoi-dohrnii"="Skeletonema dohrnii",
                        "Spisula (pseudocardium) sachalinensis"="Spisula sachalinensis",
                        "Tenualosa ilisha (juvenile)"="Tenualosa ilisha")) %>%
  # Mark ones with punctuation still
  mutate(punct=grepl("[[:punct:]]", sciname))

# Inspect species with punctuation - these 3 are correct
spp_key1 %>% filter(type=="group" & punct==T) %>% pull(sciname) %>% sort()

# Inspect species with more than two words


# Identify names to check
names_to_check1 <- spp_key1 %>% filter(type=="species") %>% pull(sciname)
# wrong_names1 <- freeR::check_names(names_to_check1)

# Identify names that aren't right
wrong_names1 <- freeR::check_names(names_to_check1)

# Build suggestions data frame
spp_suggestions1 <- taxize::gnr_resolve(sci = wrong_names1[1:10], best_match_only=T,  canonical = T, cap_first=T)

# Species key 1
spp_key2 <- spp_key1 %>%
  # Add suggested fixes
  left_join(spp_suggestions1 %>% select(user_supplied_name, matched_name2), by=c("sciname"="user_supplied_name")) %>%
  # Adopt suggested name
  mutate(sciname2=ifelse(!is.na(matched_name2), matched_name2, sciname)) %>%
  # Simplify
  select(type, sciname_orig, sciname, sciname2)

# Identify names to check
names_to_check2 <- spp_key2 %>% filter(type=="species") %>% pull(sciname2)
wrong_names2 <- freeR::check_names(names_to_check2)



# Export data
################################################################################

# Export data
saveRDS(data2, file=file.path(outdir, "AFCD_data.Rds"))







