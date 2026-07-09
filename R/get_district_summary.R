#' Per-district summary: number of works and total estimated cost (₹ lakh).
#'
#' The estimated-cost column uses the Hindi header from the source data.
get_district_summary <- function(works_long) {
  cost_col <- "कार्यदायी संस्था द्वारा आगणित लागत (लाख में )"

  works_long |>
    dplyr::mutate(
      est_cost_lakh = suppressWarnings(as.numeric(.data[[cost_col]]))
    ) |>
    dplyr::group_by(districtId, districtName) |>
    dplyr::summarise(
      n_works             = dplyr::n(),
      total_est_cost_lakh = sum(est_cost_lakh, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(n_works))
}
