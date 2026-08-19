#' Download a dataset from data.gouv.fr
#'
#' Downloads the first tabular resource of a dataset and parses it into
#' tibbles with `format_tibble()`. The dataset is identified by its `id`,
#' which is the stable, unique identifier returned in the `id` column of
#' [dg_list_datasets()]. For backwards compatibility, an exact title is also
#' accepted and is resolved by searching the platform.
#'
#' @param id The identifier of the dataset to download (or, as a fallback, its
#'   exact title). Identifiers are unique and stable, so they are the
#'   recommended way to address a dataset; titles can collide or change over
#'   time.
#' @param remove_na Whether to drop rows containing any `NA` value (passed to
#'   `format_tibble()`). Defaults to `FALSE`.
#'
#' @return A named list of [tibble::tibble()] containing the parsed data. A
#'   ZIP resource may contain several parseable files, in which case the list
#'   has one element per file (named after it); other formats yield a single
#'   element named after the resource. Each table carries a trailing `.id`
#'   column holding its stable, unique address
#'   (`<dataset_id>::<resource_id>(::<file>)`), re-fetchable with
#'   [dg_refetch()].
#'
#' @export
#' @examplesIf interactive()
#' id <- "6397c0ff56d3963118a18345"
#' tables <- dg_pull_dataset(id)
#' head(tables[[1]])
dg_pull_dataset <- function(id, remove_na = FALSE) {
  dataset <- find_dataset(id)
  # Try the dataset's tabular resources in order, keeping the first that
  # actually parses. data.gouv's declared formats are not always accurate, so a
  # candidate can fail to read as a table (e.g. a `json` resource serving a
  # metadata document); we skip those rather than erroring on the first one.
  parsed <- read_first_parseable_resource(dataset)
  data <- parsed$data
  resource <- parsed$resource
  if (is.data.frame(data)) {
    # A non-ZIP resource is a single table: wrap it so the return is always a
    # named list of tibbles, consistently with a multi-file ZIP resource.
    name <- resource$title %||% "data"
    tbl <- format_tibble(data, remove_na = remove_na)
    tbl$.id <- compose_table_id(dataset$id, resource$id)
    return(stats::setNames(list(tibble::as_tibble(tbl)), name))
  }
  # A ZIP resource is a named list of tables: format and tag each element.
  Map(function(tbl, file) {
    tbl <- format_tibble(tbl, remove_na = remove_na)
    tbl$.id <- compose_table_id(dataset$id, resource$id, file)
    tibble::as_tibble(tbl)
  }, data, names(data))
}