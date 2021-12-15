

library(taxize)




spp_suggestions <- gnr_resolve(sci = wrong_names[1:100 ], best_match_only=T,  canonical = T, cap_first=T)
