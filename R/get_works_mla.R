#' Attach canonical constituency columns to the parsed works table.
#'
#' Adds `constituency_key_canonical` (the merge target from
#' `constituency_overrides()`, identical to `constituency_key` when no override
#' applies) and `constituency_canonical` (the canonical spelling from the
#' crosswalk). This is the analysis-ready per-work table.
get_works_mla <- function(works_by_mla, constituency_crosswalk) {
  ov <- constituency_overrides()
  key_to_canon <- function(k) dplyr::coalesce(ov$canonical_key[match(k, ov$variant_key)], k)

  canon_lookup <- constituency_crosswalk |>
    dplyr::select(constituency_key, constituency_canonical = constituency)

  works_by_mla |>
    dplyr::mutate(
      constituency_key_canonical = ifelse(
        is.na(constituency_key), NA_character_, key_to_canon(constituency_key)
      ),
      .after = constituency_key
    ) |>
    dplyr::left_join(
      canon_lookup,
      by = c("constituency_key_canonical" = "constituency_key")
    ) |>
    dplyr::relocate(constituency_canonical, .after = constituency_key_canonical)
}
