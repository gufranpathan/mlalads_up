#' Read the portal's MLA-wise summary (Legislative Assembly, FY 2023-24).
#'
#' Returns one tidy row per MLA (the state-wide "- Total" row is excluded and
#' surfaced separately via `attr(x, "total_row")`). Count columns are integers;
#' the source stores blank cells as 0. Names/constituencies stay verbatim Hindi.
get_mla_summary <- function(mla_summary_json_path) {
  raw <- jsonlite::fromJSON(mla_summary_json_path, simplifyVector = TRUE)

  count_cols <- c("recommended_works", "pending_0_45", "pending_45_60",
                  "pending_60_plus", "total_pending", "sanctioned_0_45",
                  "sanctioned_45_60", "sanctioned_60_plus", "total_sanctioned",
                  "rejected")

  recs <- tibble::as_tibble(raw$records)
  recs[count_cols] <- lapply(recs[count_cols], function(x) as.integer(round(as.numeric(x))))

  attr(recs, "total_row")   <- raw$total_row
  attr(recs, "reported_mla_count") <- raw$mla_count
  recs
}
