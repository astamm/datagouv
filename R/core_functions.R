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
#' @noRd
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
    # Drop any row that contains at least one missing value (tidyr::drop_na equivalent)
    out <- out[stats::complete.cases(out), ]
  }
  out
}

#' Compute summary metrics for a dataset
#'
#' Computes key metrics describing a parsed dataset: its in-memory weight in
#' kilobytes, the number of variables, the number of numeric and non-numeric
#' variables, the number of rows and the proportion of missing values.
#'
#' @param x A data frame or tibble (as returned by [dg_pull_dataset()]).
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
  numeric_vars <- vapply(x, is.numeric, logical(1))
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

#' Summarise several datasets
#'
#' Applies [get_summary()] to a collection of datasets and combines the
#' resulting metrics into a single tibble. If `datasets` is `NULL`, the first
#' `n` datasets returned by [dg_list_datasets()] are downloaded and summarised.
#'
#' @param datasets Either a named list of tibbles, a character vector of
#'   dataset identifiers (or exact titles), or `NULL` (the default) to use the
#'   first `n` datasets from [dg_list_datasets()].
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
    catalog <- dg_list_datasets(n = n)
    # Label each downloaded table with the dataset title (disambiguating any
    # title shared by several datasets by appending its id), but address the
    # download by the stable, unique identifier.
    datasets <- uniquify_names(stats::setNames(catalog$id, catalog$title))
    datasets <- lapply(datasets, dg_pull_dataset)
  } else if (is.character(datasets)) {
    # Elements may be identifiers or, as a fallback, exact titles.
    datasets <- stats::setNames(datasets, datasets)
    datasets <- lapply(datasets, dg_pull_dataset)
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

  res <- mapply(function(df, nm) get_summary(df, name = nm), datasets, names(datasets), SIMPLIFY = FALSE)
  do.call(rbind, res)
}

#' Download datasets and compute their metrics
#'
#' Wrapper that downloads several datasets with [dg_pull_dataset()], computes
#' their summary metrics with [summarise_datasets()] and returns both the raw
#' downloaded tibbles and the metrics in a single list.
#'
#' @param ids A character vector of dataset identifiers to download (or exact
#'   titles, as a fallback). Identifiers are the stable, unique values in the
#'   `id` column of [dg_list_datasets()].
#' @param remove_na Whether to drop rows containing any `NA` value (passed to
#'   [dg_pull_dataset()]). Defaults to `FALSE`.
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
  datasets <- lapply(datasets, function(x) dg_pull_dataset(x, remove_na = remove_na))
  metrics <- summarise_datasets(datasets)
  list(datasets = datasets, metrics = metrics)
}
