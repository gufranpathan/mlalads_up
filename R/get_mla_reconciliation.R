#' Reconcile the MLA-wise summary against the work-level data.
#'
#' Returns a list of comparison tables:
#'   - `internal`   : sum of per-MLA rows vs the portal's "- Total" row + row count
#'   - `grand`      : summary assembly totals vs work-level counts (proposer_role
#'                    == "MLA"). Only "recommended" ~ unique works is comparable;
#'                    per-work sanction status is NOT retained in the work-level
#'                    table (the scrape's dedup collapsed every work to its
#'                    "proposed" bucket), so sanctioned/rejected are summary-only.
#'   - `by_district`: recommended (summary, by nodal district) vs unique MLA
#'                    works (work-level, by district), joined on district name
#'
#' The two datasets are separate portal reports refreshed independently, so exact
#' equality is not expected — this quantifies and localises any drift.
get_mla_reconciliation <- function(mla_summary, works_mla) {
  total_row <- attr(mla_summary, "total_row")
  count_cols <- c("recommended_works", "total_pending", "total_sanctioned", "rejected")

  internal <- tibble::tibble(
    metric        = count_cols,
    records_sum   = vapply(count_cols, function(c) sum(mla_summary[[c]]), numeric(1)),
    total_row     = vapply(count_cols, function(c) as.numeric(total_row[[c]]), numeric(1))
  )
  internal$match <- internal$records_sum == internal$total_row
  internal <- rbind(
    internal,
    tibble::tibble(metric = "n_rows",
                   records_sum = nrow(mla_summary),
                   total_row = as.numeric(attr(mla_summary, "reported_mla_count")),
                   match = nrow(mla_summary) == attr(mla_summary, "reported_mla_count"))
  )

  # ---- work-level assembly (MLA) slice ----
  mla_works <- works_mla |> dplyr::filter(proposer_role == "MLA")
  # The consolidated work-level table keeps only the "proposed" bucket per work,
  # so status_bucket carries no sanction/pending/rejected signal. Flag that so we
  # don't report a false discrepancy.
  status_retained <- dplyr::n_distinct(mla_works$status_bucket) > 1

  grand <- tibble::tribble(
    ~metric,                         ~summary,                            ~work_level,
    "assembly works (recommended)",  sum(mla_summary$recommended_works),  nrow(mla_works),
    "sanctioned",                    sum(mla_summary$total_sanctioned),   NA_integer_,
    "rejected",                      sum(mla_summary$rejected),           NA_integer_
  )
  grand$diff <- grand$work_level - grand$summary
  grand$note <- c("comparable", rep("work-level status not retained (all 'proposed')", 2))

  # ---- per-district: recommended (summary) vs unique MLA works (work-level) ----
  clean_dist <- function(x) trimws(as.character(x))
  summ_dist <- mla_summary |>
    dplyr::mutate(district = clean_dist(nodal_district)) |>
    dplyr::filter(!is.na(district), district != "") |>
    dplyr::group_by(district) |>
    dplyr::summarise(summary_recommended = sum(recommended_works), .groups = "drop")
  work_dist <- mla_works |>
    dplyr::mutate(district = clean_dist(district_name)) |>
    dplyr::filter(!is.na(district), district != "") |>
    dplyr::group_by(district) |>
    dplyr::summarise(worklevel_mla_works = dplyr::n(), .groups = "drop")

  by_district <- dplyr::full_join(summ_dist, work_dist, by = "district") |>
    dplyr::mutate(
      summary_recommended = dplyr::coalesce(summary_recommended, 0L),
      worklevel_mla_works = dplyr::coalesce(worklevel_mla_works, 0L),
      diff = worklevel_mla_works - summary_recommended
    ) |>
    dplyr::arrange(dplyr::desc(abs(diff)))

  list(internal = internal, grand = grand, by_district = by_district,
       status_retained = status_retained)
}
