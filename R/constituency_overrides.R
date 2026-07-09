#' Manual constituency merges (curated, version-controlled).
#'
#' IMPORTANT: fuzzy matching on these names is unsafe — many genuinely distinct
#' UP constituencies differ by only 1-2 characters (e.g. इटवा/इटावा,
#' सैदपुर/जैदपुर, कोराव/सोराव), and the numbered MLC seats differ only by their
#' number. So merges are NOT applied automatically. Each row here is a
#' human-verified decision that two `constituency_key` values are the same seat.
#'
#' Schema: variant_key  -> canonical_key
#' Add a row only after confirming the two keys are truly the same constituency
#' (the `constituency_crosswalk` target lists fuzzy near-duplicates to review).
constituency_overrides <- function() {
  tibble::tribble(
    ~variant_key, ~canonical_key,
    # e.g. "मुरादाबाद-खण्डस्नातक-1", "मुरादाबाद-खण्डस्नातक",   # <- confirm before enabling
  )
}
