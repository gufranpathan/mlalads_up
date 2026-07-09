# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this project is

Scraping and cleaning work-level data from the Uttar Pradesh MLA LADS portal
(**mlaladsup.in**). This is a **data / research** project: raw JSON is scraped
from the portal (see the reproducibility doc) and cleaned through an R
[`targets`](https://books.ropensci.org/targets/) pipeline, with dependencies
pinned by [`renv`](https://rstudio.github.io/renv/).

## Layout

- `_targets.R` — the pipeline definition (Inputs → Readers → Cleaning →
  Analysis → Outputs).
- `R/` — helper functions, one per file, each named `get_<target>` (the
  convention `targets` expects here).
- `data/mlaladsup_ALL_districts_FY2023-24_works.json` — the raw dataset (~117 MB,
  30,344 works across 75 districts, FY 2023-24). **Do not** load the whole file
  into context; it is large. Use `head`/targeted parsing, or read a target's
  value with `tar_read()`.
- `data/processed/` — pipeline outputs (e.g. cleaned CSV). Gitignored.
- `docs/mlaladsup_scrape_reproducibility.md` — the authoritative spec for the
  scrape: API contract, scraper code, district IDs, buckets, checklist. Read this
  before changing anything about how data is collected.
- `README.md` — human-facing overview.

## Running the pipeline

Always from the project root, and **never** with `--vanilla` (it skips
`.Rprofile`, so renv won't activate):

```bash
Rscript --no-save --no-restore -e "targets::tar_make()"
```

- Inspect a result: `tar_read(district_summary)` / `tar_load(works_long)`.
- What's stale: `tar_outdated()`.
- After `renv::install(...)`, run `renv::snapshot()` and commit `renv.lock`.
  Never use `install.packages()` in this project.

Current targets: `raw_json_path` (file) → `raw_json` → `works_long`
(tidy, one row per work, 30,344 rows, original Hindi headers) → `works_clean`
(same table with clean English column names) → `district_summary` /
`works_csv_path`.

## Column names / data dictionary

- `R/column_dictionary.R` is the **single source of truth** for the Hindi→English
  column mapping and descriptions. `get_works_clean()` renames by it (positional,
  with a column-count guard).
- `data_dictionary.md` is **generated** — run
  `Rscript --no-save --no-restore scripts/build_data_dictionary.R` after editing
  the dictionary (requires `tar_make()` to have run, since it reads the exact
  Hindi headers from `works_long`). Never hand-edit `data_dictionary.md`.
- Note two abbreviations in the source: **IDA** (आईoडीoएo, the district nodal
  agency) and **IA** (आईoएo, implementing agency) — kept distinct as they appear
  in the portal.

## Domain facts worth keeping in mind

- Column names in the data are **Hindi**. The unique key per work is
  `कार्य आईoडीo` (Work ID). Preserve Unicode carefully — never mangle it.
- The portal returns the work list **only** when the request is sent with
  `Content-Type: application/json`; other content types silently return a
  different (fund-summary) table. This is the #1 gotcha.
- The wire body is a literal string `{'obj':{...}}` (single-quoted `obj`), not
  standard JSON — the server parses it as a string.
- `yearId` selects the financial year: 2 = 2023-24, 3 = 2024-25, 4 = 2025-26,
  5 = 2026-27. Only FY 2023-24 has been scraped so far.
- Works are stored under 8 status buckets and deduplicated by Work ID, so
  bucket rows (~60,688) are ~2× unique works (~30,344).

## Working conventions

- When writing scripts to process the JSON, put them where the user asks;
  default to `scratchpad` for throwaway analysis and the repo for keepers.
- Some field values contain embedded HTML (`<a href>` links to DPRs/photos).
  Keep them unless the user wants plain text — they hold document URLs.
- If asked to scrape more data, follow the etiquette in the reproducibility doc:
  keep the 400–500 ms inter-request delay against the government server.
- This is a Windows environment; the primary shell is PowerShell. A Bash tool is
  also available for POSIX scripts.
