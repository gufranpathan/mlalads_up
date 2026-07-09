#' Parse the scraped MLA LADS JSON into an R list.
#'
#' Kept as a plain list (not simplified to a data frame) so the nested
#' per-district `works` arrays survive intact for downstream flattening.
get_raw_json <- function(raw_json_path) {
  jsonlite::fromJSON(raw_json_path, simplifyVector = FALSE)
}
