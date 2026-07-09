#' Write the cleaned per-work table to CSV and return its path.
#'
#' Write-then-return so the `format = "file"` target hashes a file that
#' already exists. UTF-8 output preserves the Hindi column names and values.
get_works_csv_path <- function(works_long) {
  out_dir <- "data/processed"
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

  out <- file.path(out_dir, "works_FY2023-24_clean.csv")
  readr::write_excel_csv(works_long, out)
  out
}
