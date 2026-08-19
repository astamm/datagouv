#' Re-fetch a single parsed table by its stable identifier
#'
#' Downloads again the exact table addressed by a composed table id as stored
#' in the `.id` column of the tables returned by [dg_pull_dataset()]. Because
#' the id is built from the platform's own stable identifiers (dataset id +
#' resource id, plus the file name inside a ZIP), this reproducibly returns the
#' same table, independent of the human-readable list keys.
#'
#' @param id A composed table id of the form `<dataset_id>::<resource_id>` or
#'   `<dataset_id>::<resource_id>::<file>`.
#' @param remove_na Whether to drop rows containing any `NA` value (passed to
#'   `format_tibble()`). Defaults to `FALSE`.
#'
#' @return A [tibble::tibble()] — the single re-fetched table (the id addresses
#'   one table, not a multi-file ZIP as a whole).
#'
#' @export
#' @examplesIf interactive()
#' tables <- dg_pull_dataset("6397c0ff56d3963118a18345")
#' again <- dg_refetch(tables[[1]]$.id[1])
dg_refetch <- function(id, remove_na = FALSE) {
  parts <- parse_table_id(id)
  dataset <- fetch_dataset(parts$dataset_id)
  resources <- dataset$resources
  hit <- Filter(function(r) identical(r$id, parts$resource_id), resources)
  if (length(hit) == 0) {
    stop(
      "Resource '", parts$resource_id,
      "' was not found on dataset '", parts$dataset_id, "'.", call. = FALSE
    )
  }
  resource <- hit[[1]]

  tbl <- if (is.null(parts$file)) {
    read_resource(resource)
  } else {
    read_one_zip_file(resource, parts$file)
  }
  tbl <- format_tibble(tbl, remove_na = remove_na)
  tbl$.id <- id
  tibble::as_tibble(tbl)
}
