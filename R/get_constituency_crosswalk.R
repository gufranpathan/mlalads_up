#' Reviewable crosswalk: one row per (canonicalised) legislator seat.
#'
#' Aggregates the parsed works to a per-constituency reference table and applies
#' any human-verified merges from `constituency_overrides()`. Fuzzy matching is
#' used ONLY to populate `near_duplicates` (a review hint) — it never merges on
#' its own, because distinct UP seats routinely differ by 1-2 characters.
#' Pairs that differ only in digits (e.g. the numbered MLC seats) are excluded
#' from the hints, since a differing number always means a different seat.
get_constituency_crosswalk <- function(works_by_mla) {
  ov <- constituency_overrides()
  key_to_canon <- function(k) dplyr::coalesce(ov$canonical_key[match(k, ov$variant_key)], k)
  most_common <- function(x) {
    x <- x[!is.na(x)]
    if (!length(x)) return(NA_character_)
    names(sort(table(x), decreasing = TRUE))[1]
  }

  xw <- works_by_mla |>
    dplyr::filter(!is.na(constituency_key)) |>
    dplyr::mutate(canon_key = key_to_canon(constituency_key)) |>
    dplyr::group_by(proposer_role, house, canon_key) |>
    dplyr::summarise(
      constituency        = most_common(constituency),
      n_works             = dplyr::n(),
      n_districts         = dplyr::n_distinct(district_name),
      districts           = paste(sort(unique(district_name)), collapse = "; "),
      example_proposer    = most_common(proposer_person),
      n_variant_spellings = dplyr::n_distinct(constituency),
      .groups = "drop"
    ) |>
    dplyr::rename(constituency_key = canon_key) |>
    dplyr::arrange(proposer_role, dplyr::desc(n_works))

  # Fuzzy near-duplicate hints (same role), review-only. Digits stripped with
  # both ASCII and Devanagari ranges so numbered seats are treated as distinct.
  strip_digits <- function(s) gsub("[0-9०-९]", "", s)
  xw$near_duplicates <- NA_character_
  for (role in unique(xw$proposer_role)) {
    idx  <- which(xw$proposer_role == role)
    keys <- xw$constituency_key[idx]
    labs <- xw$constituency[idx]
    if (length(idx) < 2) next
    d <- adist(keys)
    for (a in seq_along(idx)) {
      hits <- character(0)
      for (b in seq_along(idx)) {
        if (a == b) next
        ml <- max(nchar(keys[a]), nchar(keys[b]))
        digit_only <- strip_digits(keys[a]) == strip_digits(keys[b]) &&
          grepl("[0-9०-९]", paste0(keys[a], keys[b]))
        if (!digit_only && d[a, b] <= 2 && d[a, b] / ml <= 0.25) hits <- c(hits, labs[b])
      }
      if (length(hits)) xw$near_duplicates[idx[a]] <- paste(hits, collapse = " | ")
    }
  }

  xw$is_manual_override <- xw$constituency_key %in% ov$canonical_key
  xw
}
