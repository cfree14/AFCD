#' Aquatic Foods Composition Database (AFCD)
#'
#' A cleaned version of the Aquatic Foods Composition Database (AFCD).
#'
#' @format A data frame with the following attributes::
#' \describe{
#'   \item{sciname}{Scientific name}
#'   \item{study_id}{Study id}
#'   \item{iso3}{ISO3 of source country(s)}
#'   \item{fao3}{}
#'   \item{prod_catg}{Production category (farmed, wild capture, unknown)}
#'   \item{food_part}{Part of food}
#'   \item{food_prep}{Preparation of food}
#'   \item{food_name}{Name of food, in English}
#'   \item{food_name_orig}{Name of food, in original data}
#'   \item{notes}{Notes}
#'   \item{nutrient}{Nuteient}
#'   \item{description}{Description of nutrient}
#'   \item{units}{Units per 100g of edible food portion}
#'   \item{value}{Value}
#' }
#' @source Golden CD, Koehn JZ, Shepon A, Passarelli S, Free CM, Viana DF, Matthey H, Eurich JG, Gephart JA, Fluet-Chouinnard E, Nyboer EA, Lynch AJ, Kjellevold M, Bromage S, Charlebois P, Barange M, Vannuccini S, Cao L, Kleisner KM, Rimm EB, Danaei G, DeSisto C, Kelahan H, Fiorella KJ, Little DC, Allison EH, Fanzo J, Thilsted SH (2021) Aquatic foods to nourish nations. Nature 598: 315-320.
"afcd"

#' Aquatic Foods Composition Database (AFCD) nutrient key
#'
#' Nutrient key for the Aquatic Foods Composition Database (AFCD).
#'
#' @format A data frame with the following attributes::
#' \describe{
#'   \item{nutrient_type}{Nutrient type (e.g., mineral, vitamin, carbohydrate, etc.)}
#'   \item{nutrient}{Nutrient name}
#'   \item{nutrient_units}{Nutrient units}
#'   \item{nutrient_code_fao}{FAO nutrient code}
#'   \item{nutrient_desc}{Description of nutrient and value}
#'   \item{n}{Number of observations)}
#' }
#' @source Golden CD, Koehn JZ, Shepon A, Passarelli S, Free CM, Viana DF, Matthey H, Eurich JG, Gephart JA, Fluet-Chouinnard E, Nyboer EA, Lynch AJ, Kjellevold M, Bromage S, Charlebois P, Barange M, Vannuccini S, Cao L, Kleisner KM, Rimm EB, Danaei G, DeSisto C, Kelahan H, Fiorella KJ, Little DC, Allison EH, Fanzo J, Thilsted SH (2021) Aquatic foods to nourish nations. Nature 598: 315-320.
"afcd_nutrients"

#' Aquatic Foods Composition Database (AFCD) reference key
#'
#' Reference key for the Aquatic Foods Composition Database (AFCD). The AFCD utilizes a mixture of values from Food Composition Tables (FCTs) and from the peer-reviewed literature.
#'
#' @format A data frame with the following attributes::
#' \describe{
#'   \item{study_type}{Study type (Peer-reviewed literature or FCT table)}
#'   \item{study_id}{Study id}
#'   \item{citation}{Citation}
#'   \item{doi}{DOI for peer-reviewed sources and dataset link for FCT sources}
#'   \item{region}{Study region (peer-reviewed only)}
#'   \item{database}{Nuutrient database (FCT sources only)}
#'   \item{units}{Nutrients per unit (FCT sources only)}
#' }
#' @source Golden CD, Koehn JZ, Shepon A, Passarelli S, Free CM, Viana DF, Matthey H, Eurich JG, Gephart JA, Fluet-Chouinnard E, Nyboer EA, Lynch AJ, Kjellevold M, Bromage S, Charlebois P, Barange M, Vannuccini S, Cao L, Kleisner KM, Rimm EB, Danaei G, DeSisto C, Kelahan H, Fiorella KJ, Little DC, Allison EH, Fanzo J, Thilsted SH (2021) Aquatic foods to nourish nations. Nature 598: 315-320.
"afcd_refs"
