
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
data_orig <- readRDS(file.path(indir, "AFCD_data.Rds"))


# Species key
################################################################################

# Species key 1
spp_key1 <- data_orig %>%
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
  # Replace AND with comma
  mutate(sciname=gsub(" and ", ", ", sciname)) %>%
  # Add period to end of all SPPs
  mutate(sciname=gsub("spp.", "spp", sciname),
         sciname=gsub("spp", "spp.", sciname)) %>%
  # Add period to end of all trailing SPs
  mutate(sciname=gsub(" sp$", " sp.", sciname)) %>%
  # Fix a few 1 worders
  # mutate(sciname=recode(sciname,
  #                       "")) %>%
  # Add SPP to end of 1 word groups
  mutate(nwords=freeR::nwords(sciname)) %>%
  mutate(sciname=ifelse(nwords==1, paste(sciname, "spp."), sciname)) %>%
  select(-nwords) %>%
  # Mark species or group specific
  mutate(type=ifelse(grepl("spp\\.|sp\\.|,|/| x ", sciname), "group", "species")) %>% # x=hybrids, commas/slashes is multiple
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
                        "Cyprinus carpio var. specularis)"="Cyprinus carpio",
                        "Cystoseira abies-marina"="Treptacantha abies-marina", # hyphen is correct
                        "Engraulis encrasicolus)"="Engraulis encrasicolus",
                        "F. spiralis"="Farfantepenaeus spiralis",
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
  # Fix ones with more than two words
  mutate(sciname=recode(sciname,
                        "Spyridia fi lamentosa"="Spyridia filamentosa",
                        "T rachurus mediterraneus"="Trachurus mediterraneus")) %>%
  # Mark ones with punctuation still
  mutate(punct=grepl("[[:punct:]]", sciname)) %>%
  # Count number of words
  mutate(nwords_orig=freeR::nwords(sciname_orig),
         nwords=freeR::nwords(sciname)) %>%
  # Trim
  mutate(sciname=stringr::str_trim(sciname))

# Inspect groups
group_key <- spp_key1 %>%
  filter(type=="group")

# Inspect species with punctuation - these 3 are correct
spp_key1 %>% filter(type=="species" & punct==T) %>% pull(sciname) %>% sort()

# Inspect species with more than two words
spp_key1 %>% filter(type=="species" & nwords>2) %>% pull(sciname) %>% sort()

# Get taxa
taxa_key <- freeR::taxa(spp_key1$sciname)

spp_key2 <- spp_key1 %>%
  left_join(taxa_key, by="sciname")


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







