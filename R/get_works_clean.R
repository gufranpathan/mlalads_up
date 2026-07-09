#' Rename the works table's Hindi columns to clean English names.
#'
#' Uses `column_dictionary()` as the single source of truth. The dictionary is
#' ordered to match `get_works_long()`'s output, so renaming is positional; a
#' guard asserts the column count still matches before renaming, failing loudly
#' if the upstream schema ever changes.
get_works_clean <- function(works_long) {
  dict <- column_dictionary()

  if (ncol(works_long) != nrow(dict)) {
    stop(sprintf(
      "Schema drift: works_long has %d columns but the dictionary defines %d. Update R/column_dictionary.R.",
      ncol(works_long), nrow(dict)
    ))
  }

  names(works_long) <- dict$english[order(dict$order)]
  works_long
}
