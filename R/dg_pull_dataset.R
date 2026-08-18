#' Download a dataset from data.gouv.fr
#'
#' Downloads the first tabular resource of a dataset and parses it into a
#' tibble with `format_tibble()`. The dataset is identified by its `id`,
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
#' @return A [tibble::tibble()] containing the parsed data.
#'
#' @export
#' @examplesIf interactive()
#' id <- "6397c0ff56d3963118a18345"
#' df <- dg_pull_dataset(id)
#' head(df)
dg_pull_dataset <- function(id, remove_na = FALSE) {
  dataset <- find_dataset(id)
  resource <- pick_resource(dataset)
  data <- read_resource(resource)
  format_tibble(data, remove_na = remove_na)
}