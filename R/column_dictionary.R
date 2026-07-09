#' Column dictionary for the cleaned works table.
#'
#' Single source of truth mapping the source columns (in their `works_long`
#' order) to clean English names and English descriptions. Used both by
#' `get_works_clean()` to rename columns and by `scripts/build_data_dictionary.R`
#' to regenerate `data_dictionary.md` (the Hindi header for each column is read
#' from the data itself, so it is never hand-typed here).
#'
#' The `order` must match the column order produced by `get_works_long()`.
#' Columns 1-3 and the final `status_bucket` are added during scraping/flattening;
#' the rest are the portal's original ~38 Hindi fields.
column_dictionary <- function() {
  tibble::tribble(
    ~order, ~english,                              ~description,
    1L,  "district_id",                        "District identifier from the portal's district dropdown. Added during flattening.",
    2L,  "district_name",                      "District name (Hindi). Added during flattening from the district record.",
    3L,  "financial_year",                     "Financial year of the scrape scope (2023-24). Added during flattening.",
    4L,  "serial_no",                          "Row serial number (क्रम संख्या) as shown in the source popup table.",
    5L,  "work_id",                            "Unique work identifier (कार्य आईडी). Primary key; works are deduplicated on this.",
    6L,  "work_description",                   "Free-text description of the work.",
    7L,  "work_type",                          "Category of work (e.g. road, beautification, building).",
    8L,  "district_name_src",                  "District name as recorded on the work row (जनपद). Duplicates district_name.",
    9L,  "block_or_body",                      "Development block or urban local body (ब्लॉक/निकाय).",
    10L, "ward_or_gram_panchayat",             "Ward or Gram Panchayat name.",
    11L, "mohalla_or_village",                 "Mohalla (neighbourhood) or village name.",
    12L, "financial_year_src",                 "Financial year recorded on the work row (वित्तीय वर्ष). Duplicates financial_year.",
    13L, "proposed_quantity",                  "Proposed quantity, in running metres or as a unit count.",
    14L, "recommendation_date",                "Date the work was recommended/approved (अनुशंसा की तिथि).",
    15L, "proposer_name_designation_area",     "Proposer's name, designation, and constituency/area.",
    16L, "executing_agency",                   "Name of the executing agency (कार्यदायी संस्था).",
    17L, "executing_agency_nominated_date",    "Date the executing agency was nominated.",
    18L, "estimated_cost_lakh",                "Cost estimated by the executing agency, in lakh rupees.",
    19L, "dpr_link",                           "Link to the Detailed Project Report (DPR) submitted by the executing agency. HTML anchor.",
    20L, "dpr_submission_date",                "Date the DPR was submitted by the executing agency.",
    21L, "dpr_sent_for_consent_date",          "Date the DPR was forwarded by the IDA (district nodal agency) for consent.",
    22L, "mla_consent_date",                   "Date the Hon'ble MLA gave consent (माननीय विधायक द्वारा सहमति).",
    23L, "circular_link",                      "Link to the sanction circular (परिपत्र) uploaded by the IDA. HTML anchor.",
    24L, "circular_upload_date",               "Date the sanction circular was uploaded by the IDA.",
    25L, "first_installment_amount_rs",        "First installment amount released, in rupees.",
    26L, "tender_start_date",                  "Tender start date (निविदा प्रारम्भ).",
    27L, "tender_end_date",                    "Tender completion date (निविदा पूर्ण).",
    28L, "contractor_name",                    "Name of the contractor (ठेकेदार).",
    29L, "work_start_date",                    "Date work commenced (कार्य प्रारम्भ).",
    30L, "physical_progress_pct",              "Physical progress, in percent.",
    31L, "physical_progress_photo_link",       "Link to physical-progress photo(s). HTML anchor.",
    32L, "financial_progress_pct",             "Financial progress, in percent.",
    33L, "second_installment_letter_no_date",  "Letter number and date of the second installment sent by the IA (implementing agency).",
    34L, "second_installment_sanction_date",   "Date the second installment was sanctioned by the IDA.",
    35L, "second_installment_sanctioned_amount","Amount of the second installment sanctioned by the IDA.",
    36L, "second_installment_circular_link",   "Link to the sanction circular for the second installment, uploaded by the IDA. HTML anchor.",
    37L, "second_installment_release_letter_no_date","Letter number and date for the second-installment amount issued by the IDA.",
    38L, "second_installment_released_amount", "Amount of the second installment issued/released by the IDA.",
    39L, "work_completion_date",               "Date the work was completed (कार्य पूर्ण).",
    40L, "proposer_name",                      "Proposer's name (प्रस्तावक का नाम).",
    41L, "work_added_date",                    "Date the work record was added/entered (कार्य जोड़ने की तिथि).",
    42L, "status_bucket",                      "Scraper status bucket the work was first found under (proposed / pending_* / sanctioned_* / rejected).",
  )
}
