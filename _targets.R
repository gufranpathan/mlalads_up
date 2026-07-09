library(targets)
library(tarchetypes)

# Packages every target needs at runtime.
tar_option_set(
  packages = c("jsonlite", "dplyr", "tidyr", "readr", "purrr", "tibble")
)

# Source all helper functions from R/ (each named get_<target>).
tar_source()

list(
  # ---- Inputs ----
  # Raw scraped JSON, tracked by content hash so downstream targets re-run
  # only when the file actually changes.
  tar_target(
    raw_json_path,
    "data/mlaladsup_ALL_districts_FY2023-24_works.json",
    format = "file"
  ),

  # ---- Readers ----
  # Parse the nested JSON (meta + per-district works) into an R list.
  tar_target(raw_json, get_raw_json(raw_json_path)),

  # ---- Cleaning ----
  # Flatten every district's works into one tidy, one-row-per-work table
  # (original Hindi column names preserved).
  tar_target(works_long, get_works_long(raw_json)),

  # Rename the Hindi columns to clean English names (see R/column_dictionary.R).
  tar_target(works_clean, get_works_clean(works_long)),

  # Parse the proposer field into structured legislator/constituency columns.
  tar_target(works_by_mla, get_works_by_mla(works_clean)),

  # Reviewable per-seat crosswalk; applies human-verified merges and flags
  # fuzzy near-duplicates for review (see R/constituency_overrides.R).
  tar_target(constituency_crosswalk, get_constituency_crosswalk(works_by_mla)),

  # Analysis-ready per-work table with canonical constituency columns.
  tar_target(works_mla, get_works_mla(works_by_mla, constituency_crosswalk)),

  # ---- Analysis ----
  # Per-district summary: work counts and total estimated cost.
  tar_target(district_summary, get_district_summary(works_clean)),

  # ---- Outputs ----
  # Write the enriched per-work table (incl. MLA columns) to CSV; return path.
  tar_target(works_csv_path, get_works_csv_path(works_mla), format = "file"),

  # Write the constituency crosswalk (human-review artifact) to CSV.
  tar_target(crosswalk_csv_path, get_crosswalk_csv_path(constituency_crosswalk),
             format = "file")
)
