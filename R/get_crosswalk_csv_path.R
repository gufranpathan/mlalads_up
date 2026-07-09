#' Write the constituency crosswalk to CSV and return its path.
#'
#' UTF-8 (with BOM via write_excel_csv) so the Hindi names open cleanly in
#' Excel. This file is the human-review artifact: check `near_duplicates` and,
#' where a hint is a genuine same-seat variant, add a row to
#' `constituency_overrides()` and re-run the pipeline.
get_crosswalk_csv_path <- function(constituency_crosswalk) {
  out_dir <- "data/processed"
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

  out <- file.path(out_dir, "constituency_crosswalk.csv")
  readr::write_excel_csv(constituency_crosswalk, out)
  out
}
