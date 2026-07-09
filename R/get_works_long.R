#' Flatten every district's works into one tidy table (one row per work).
#'
#' Each work keeps its original Hindi column names; district id/name and the
#' scraper's `__bucket` tag are carried through. Fields absent from a given
#' work become NA so the rows bind cleanly.
get_works_long <- function(raw_json) {
  district_tbls <- purrr::map(raw_json$districts, function(d) {
    if (length(d$works) == 0) return(NULL)

    rows <- purrr::map(d$works, function(w) {
      # Replace NULLs with NA and collapse any stray length>1 fields so each
      # value is a scalar, then coerce to a one-row tibble.
      w <- purrr::map(w, function(v) {
        if (is.null(v) || length(v) == 0) return(NA)
        if (length(v) > 1) return(paste(unlist(v), collapse = "; "))
        v
      })
      tibble::as_tibble(w)
    })

    dplyr::bind_rows(rows) |>
      dplyr::mutate(
        districtId   = d$districtId,
        districtName = d$districtName,
        financialYear = d$financialYear,
        .before = 1
      )
  })

  dplyr::bind_rows(purrr::compact(district_tbls))
}
