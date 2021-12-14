# Aquatic Foods Composition Database (cleaned)

## Overview

This R package contains a cleaned version of the Aquatic Foods Composition Database (AFCD) developed by [Golden et al. (2016)](https://www.nature.com/articles/s41586-021-03917-1):

* Golden CD**, Koehn JZ**, Shepon A**, Passarelli S**, Free CM**, Viana DF**, Matthey H, Eurich JG, Gephart JA, Fluet-Chouinnard E, Nyboer EA, Lynch AJ, Kjellevold M, Bromage S, Charlebois P, Barange M, Vannuccini S, Cao L, Kleisner KM, Rimm EB, Danaei G, DeSisto C, Kelahan H, Fiorella KJ, Little DC, Allison EH, Fanzo J, Thilsted SH (2021) Aquatic foods to nourish nations. _Nature_ 598: 315-320. _** denotes shared first authorship_

## Installation

The "AFCD" R package can be installed from GitHub with:

``` r
# Run if you don't already have devtools installed
install.packages("devtools")

# Run once devtools is successfully installed
devtools::install_github("cfree14/AFCD", force=T)
library(AFCD)
```

## Datasets

The package contains the following datasets:

1. Aquatic Foods Composition Database: `?afcd`
2. Aquatic Foods Composition Database species key: `?afcd_spp`
3. Aquatic Foods Composition Database references: `?afcd_refs`

The data were accessed from this [Harvard Dataverse repository](https://dataverse.harvard.edu/dataverse/afcd) with additional information accessed via this [GitHub repository](https://github.com/zachkoehn/aquatic_foods_nutrient_database). The data were formatted by [Chris Free](https://marine.rutgers.edu/~cfree/). Please contact Chris Free (cfree14@gmail.com) with questions about this repository and the original authors with questions about the data or paper.

## Citation

Please reference the original paper when using this data:

* Golden CD, Koehn JZ, Shepon A, Passarelli S, Free CM, Viana DF, Matthey H, Eurich JG, Gephart JA, Fluet-Chouinnard E, Nyboer EA, Lynch AJ, Kjellevold M, Bromage S, Charlebois P, Barange M, Vannuccini S, Cao L, Kleisner KM, Rimm EB, Danaei G, DeSisto C, Kelahan H, Fiorella KJ, Little DC, Allison EH, Fanzo J, Thilsted SH (2021) Aquatic foods to nourish nations. _Nature_ 598: 315-320.
