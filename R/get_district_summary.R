#' Per-district summary: number of works and total estimated cost (₹ lakh).
#'
#' Consumes the cleaned works table (English column names).
get_district_summary <- function(works_clean) {
  works_clean |>
    dplyr::mutate(
      est_cost_lakh = suppressWarnings(as.numeric(estimated_cost_lakh))
    ) |>
    dplyr::group_by(district_id, district_name) |>
    dplyr::summarise(
      n_works             = dplyr::n(),
      total_est_cost_lakh = sum(est_cost_lakh, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(n_works))
}
