#' List datasets available on data.gouv.fr
#'
#' Collects the names (titles) of datasets published on the data.gouv.fr
#' platform. By default it returns the first `n` datasets; use `q` to search
#' titles and descriptions server-side instead of enumerating the whole
#' catalog.
#'
#' Fetching *every* dataset on the platform means paging through tens of
#' thousands of records in hundreds of HTTP requests and is both slow and
#' fragile, so the default is deliberately bounded. Set `n = Inf` to return
#' all titles regardless of count.
#'
#' @param q Optional full-text search query. When given, only datasets
#'   matching `q` are returned (the API performs the search). Defaults to
#'   `NULL`, meaning no filtering.
#' @param n Maximum number of datasets to return. Defaults to `1000`.
#'   Set to `Inf` to retrieve everything (the whole catalog).
#'
#' @return A [tibble::tibble()] with one row per matching dataset and the
#'   columns `title`, `id`, `description` and `slug`. The `id` column holds the
#'   stable, unique dataset identifier used to address a dataset with
#'   [get_dataset()].
#'
#' @export
#' @examplesIf interactive()
#' datasets <- list_datasets(n = 20)
#' head(datasets)
#'
#' # Search server-side instead of downloading the whole catalog.
#' cycle <- list_datasets(q = "vélo", n = 10)
list_datasets <- function(q = NULL, n = 1000) {
  datasets <- fetch_all_datasets(q = q, n = n)
  # purrr::map_chr(datasets, ~ .x$title %||% NA_character_)
  purrr::map_dfr(datasets, \(.x) {
    list(
      title = .x$title %||% NA_character_,
      id = .x$id %||% NA_character_,
      description = .x$description %||% NA_character_,
      slug = .x$slug %||% NA_character_
    )
  })
}

#' Parse a resource into a tidy tibble
#'
#' Converts a data frame (e.g. read with `readr`) into a [tibble::tibble()] and,
#' optionally, drops all rows that contain at least one missing value.
#'
#' @param x A data frame or tibble to convert.
#' @param remove_na Whether to drop rows containing any `NA` value.
#'   Defaults to `FALSE`.
#'
#' @return A [tibble::tibble()].
#'
#' @export
#' @examples
#' df <- data.frame(a = c(1, 2, NA), b = c("x", NA, "z"))
#' format_tibble(df)
#' format_tibble(df, remove_na = TRUE)
format_tibble <- function(x, remove_na = FALSE) {
  if (!is.data.frame(x)) {
    stop("`x` must be a data frame or tibble.", call. = FALSE)
  }
  out <- tibble::as_tibble(x)
  if (remove_na) {
    out <- tidyr::drop_na(out)
  }
  out
}

#' Compute summary metrics for a dataset
#'
#' Computes key metrics describing a parsed dataset: its in-memory weight in
#' kilobytes, the number of variables, the number of numeric and non-numeric
#' variables, the number of rows and the proportion of missing values.
#'
#' @param x A data frame or tibble (as returned by [get_dataset()]).
#' @param name An optional label attached to the result (e.g. the dataset
#'   title). When `NULL` (the default), the label is taken from the expression
#'   passed to `x` when possible.
#'
#' @return A [tibble::tibble()] with a single row and the following columns:
#'   `dataset`, `size_kb`, `n_vars`, `n_numeric`, `n_non_numeric`, `n_rows`
#'   and `prop_missing`.
#'
#' @export
#' @examples
#' get_summary(iris, name = "iris")
get_summary <- function(x, name = NULL) {
  if (!is.data.frame(x)) {
    stop("`x` must be a data frame or tibble.", call. = FALSE)
  }
  if (is.null(name)) {
    name <- deparse(substitute(x))
  }
  numeric_vars <- purrr::map_lgl(x, is.numeric)
  n_total <- nrow(x) * ncol(x)

  tibble::tibble(
    dataset = name,
    size_kb = as.numeric(utils::object.size(x)) / 1024,
    n_vars = ncol(x),
    n_numeric = sum(numeric_vars),
    n_non_numeric = ncol(x) - sum(numeric_vars),
    n_rows = nrow(x),
    prop_missing = if (n_total == 0) 0 else sum(is.na(x)) / n_total
  )
}

#' Download a dataset from data.gouv.fr
#'
#' Downloads the first tabular resource of a dataset and parses it into a
#' tibble with [format_tibble()]. The dataset is identified by its `id`,
#' which is the stable, unique identifier returned in the `id` column of
#' [list_datasets()]. For backwards compatibility, an exact title is also
#' accepted and is resolved by searching the platform.
#'
#' @param id The identifier of the dataset to download (or, as a fallback, its
#'   exact title). Identifiers are unique and stable, so they are the
#'   recommended way to address a dataset; titles can collide or change over
#'   time.
#' @param remove_na Whether to drop rows containing any `NA` value (passed to
#'   [format_tibble()]). Defaults to `FALSE`.
#'
#' @return A [tibble::tibble()] containing the parsed data.
#'
#' @export
#' @examplesIf interactive()
#' id <- "6397c0ff56d3963118a18345"
#' df <- get_dataset(id)
#' head(df)
get_dataset <- function(id, remove_na = FALSE) {
  dataset <- find_dataset(id)
  resource <- pick_resource(dataset)
  data <- read_resource(resource)
  format_tibble(data, remove_na = remove_na)
}

#' Summarise several datasets
#'
#' Applies [get_summary()] to a collection of datasets and combines the
#' resulting metrics into a single tibble. If `datasets` is `NULL`, the first
#' `n` datasets returned by [list_datasets()] are downloaded and summarised.
#'
#' @param datasets Either a named list of tibbles, a character vector of
#'   dataset identifiers (or exact titles), or `NULL` (the default) to use the
#'   first `n` datasets from [list_datasets()].
#' @param n Number of datasets to summarise when `datasets` is `NULL`.
#'   Defaults to `100`.
#'
#' @return A [tibble::tibble()] with one row per dataset and the columns
#'   described in [get_summary()].
#'
#' @export
#' @examplesIf interactive()
#' summarise_datasets(datasets = list(iris = iris), n = 2)
summarise_datasets <- function(datasets = NULL, n = 100) {
  if (is.null(datasets)) {
    catalog <- list_datasets(n = n)
    # Label each downloaded table with the dataset title (disambiguating any
    # title shared by several datasets by appending its id), but address the
    # download by the stable, unique identifier.
    datasets <- stats::setNames(catalog$id, catalog$title) |>
      uniquify_names()
    datasets <- purrr::map(datasets, get_dataset)
  } else if (is.character(datasets)) {
    # Elements may be identifiers or, as a fallback, exact titles.
    datasets <- stats::setNames(datasets, datasets)
    datasets <- purrr::map(datasets, get_dataset)
  } else if (!is.list(datasets)) {
    stop("`datasets` must be a list of tibbles, a character vector or NULL.",
      call. = FALSE
    )
  }

  if (length(datasets) == 0) {
    return(tibble::tibble(
      dataset = character(),
      size_kb = numeric(),
      n_vars = integer(),
      n_numeric = integer(),
      n_non_numeric = integer(),
      n_rows = integer(),
      prop_missing = numeric()
    ))
  }

  purrr::imap(datasets, function(df, nm) get_summary(df, name = nm)) |>
    dplyr::bind_rows()
}

#' Download datasets and compute their metrics
#'
#' Wrapper that downloads several datasets with [get_dataset()], computes
#' their summary metrics with [summarise_datasets()] and returns both the raw
#' downloaded tibbles and the metrics in a single list.
#'
#' @param ids A character vector of dataset identifiers to download (or exact
#'   titles, as a fallback). Identifiers are the stable, unique values in the
#'   `id` column of [list_datasets()].
#' @param remove_na Whether to drop rows containing any `NA` value (passed to
#'   [get_dataset()]). Defaults to `FALSE`.
#'
#' @return A list with two components:
#'   \item{datasets}{A named list of the downloaded tibbles.}
#'   \item{metrics}{A tibble of summary metrics, as returned by
#'     [summarise_datasets()].}
#'
#' @export
#' @examplesIf interactive()
#' out <- wrapper_datasets("6397c0ff56d3963118a18345")
#' names(out)
wrapper_datasets <- function(ids, remove_na = FALSE) {
  datasets <- stats::setNames(ids, ids)
  datasets <- purrr::map(datasets, ~ get_dataset(.x, remove_na = remove_na))
  metrics <- summarise_datasets(datasets)
  list(datasets = datasets, metrics = metrics)
}
