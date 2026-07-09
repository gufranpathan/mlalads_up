#' Parse the proposer field into structured legislator / constituency columns.
#'
#' Splits `proposer_name_designation_area` (e.g.
#' "श्री विनय वर्मामाननीय विधायक विo सo शोहरतगढ़ (विधान सभा)") into:
#'   - proposer_person    : name text before the "माननीय विधायक" marker
#'   - proposer_role      : "MLA" (Vidhan Sabha) or "MLC" (Vidhan Parishad)
#'   - house              : "Vidhan Sabha" / "Vidhan Parishad"
#'   - constituency       : constituency/seat text, with the "विo सo" prefix stripped
#'   - constituency_key   : whitespace-collapsed key for joining across spelling
#'                          variants (e.g. "गोरखपुर - अयोध्या" == "गोरखपुर-अयोध्या")
#'
#' House/role are read from the TRAILING parenthetical, not from a substring
#' search, because some MLC seats literally contain "विधान सभा 16" in their name.
#' Rows with a blank/"()" proposer get NA for all parsed fields.
get_works_by_mla <- function(works_clean) {
  s <- works_clean$proposer_name_designation_area
  s <- ifelse(is.na(s), "", stringr::str_squish(s))

  # Trailing "(...)" tag → house / role
  house_hi <- stringr::str_match(s, "\\(([^)]*)\\)\\s*$")[, 2]
  house <- dplyr::case_when(
    stringr::str_detect(house_hi, "परिषद") ~ "Vidhan Parishad",
    stringr::str_detect(house_hi, "सभा")   ~ "Vidhan Sabha",
    TRUE ~ NA_character_
  )
  proposer_role <- dplyr::case_when(
    house == "Vidhan Parishad" ~ "MLC",
    house == "Vidhan Sabha"    ~ "MLA",
    TRUE ~ NA_character_
  )

  # Person name: everything before "माननीय" (Hon'ble)
  proposer_person <- stringr::str_trim(stringr::str_extract(s, "^.*?(?=माननीय)"))
  proposer_person <- ifelse(is.na(proposer_person) | proposer_person == "",
                            NA_character_, proposer_person)

  # Constituency/seat: text between "विधायक" and the trailing "(...)"
  constituency <- stringr::str_match(s, "विधायक\\s*(.*?)\\s*\\([^)]*\\)\\s*$")[, 2]
  # Strip the "विo सo" / "वि0स0" (Vidhan Sabha) abbreviation prefix.
  constituency <- stringr::str_replace(constituency, "^वि[o0]?\\s*स[o0]?\\s*", "")
  constituency <- stringr::str_squish(constituency)
  constituency <- ifelse(is.na(constituency) | constituency == "",
                         NA_character_, constituency)

  # Join key: drop all whitespace so spacing variants collapse together.
  constituency_key <- ifelse(is.na(constituency), NA_character_,
                             stringr::str_replace_all(constituency, "\\s+", ""))

  works_clean |>
    dplyr::mutate(
      proposer_person  = proposer_person,
      proposer_role    = proposer_role,
      house            = house,
      constituency     = constituency,
      constituency_key = constituency_key,
      .after = proposer_name_designation_area
    )
}
