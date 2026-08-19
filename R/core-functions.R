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
#' @param x A data frame or tibble (a single table, e.g. one element of the
#'   list returned by [dg_pull_dataset()]).
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
#' Applies [get_summary()] to a collection of tables and combines the resulting
#' metrics into a single tibble. If `datasets` is `NULL`, the first `n` datasets
#' returned by [dg_list_datasets()] are downloaded and summarised.
#'
#' @param datasets Either a named list of tibbles (each element is a single
#'   table, named after it), a named list of such lists (as returned by
#'   [dg_pull_dataset()]/[dg_download_many()], where a ZIP may contribute
#'   several tables), a tibble from [dg_list_datasets()] (identified by its
#'   `id` column; each dataset is downloaded and summarised), a character
#'   vector of dataset identifiers (or exact titles), or `NULL` (the default)
#'   to use the first `n` datasets from [dg_list_datasets()].
#' @param n Number of datasets to summarise when `datasets` is `NULL`.
#'   Defaults to `100`.
#'
#' @return A [tibble::tibble()] with one row per table and the columns
#'   described in [get_summary()].
#'
#' @export
#' @examples
#' # Summarise in-memory tables (no network needed).
#' summarise_datasets(datasets = list(iris = iris, mtcars = mtcars))
#'
#' @examplesIf interactive()
#' # Download and summarise the first datasets of the catalog.
#' summarise_datasets()
summarise_datasets <- function(datasets = NULL, n = 100) {
  if (is.null(datasets)) {
    catalog <- dg_list_datasets(n = n)
    # Label each downloaded dataset with its title (disambiguating any title
    # shared by several datasets by appending its id), but address the download
    # by the stable, unique identifier.
    datasets <- uniquify_names(stats::setNames(catalog$id, catalog$title))
    datasets <- lapply(datasets, dg_pull_dataset)
  } else if (is.data.frame(datasets) && "id" %in% names(datasets)) {
    # A tibble from dg_list_datasets(): download each id, labelled by title.
    catalog <- datasets
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

  datasets <- flatten_tables(datasets)

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

# Flatten a named list whose elements are either single tibbles or named lists
# of tibbles (as returned by dg_pull_dataset() for a multi-file ZIP) into a
# flat named list of tibbles, one summary row per table. When a dataset
# contributes a single table it keeps its label; when it contributes several,
# each table's name is appended to the dataset label.
flatten_tables <- function(x) {
  out <- list()
  for (nm in names(x)) {
    el <- x[[nm]]
    if (is.data.frame(el)) {
      out[[nm]] <- el
    } else {
      inner <- names(el)
      if (length(el) == 1) {
        out[[nm]] <- el[[1]]
      } else {
        for (i in seq_along(el)) {
          out[[paste0(nm, " / ", inner[i])]] <- el[[i]]
        }
      }
    }
  }
  out
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
#'   \item{datasets}{A named list of the downloaded tibbles. A ZIP dataset may
#'     contribute several tables, each named after its file.}
#'   \item{metrics}{A tibble of summary metrics, as returned by
#'     [summarise_datasets()].}�
#'
#' @export
#' @examplesIf interactive()
#' out <- dg_download_many("6397c0ff56d3963118a18345")
#' names(out)
#' out$metrics
#' head(out$datasets[[1]])
dg_download_many <- function(ids, remove_na = FALSE) {
  tables <- stats::setNames(ids, ids)
  tables <- lapply(tables, function(x) dg_pull_dataset(x, remove_na = remove_na))
  tables <- flatten_tables(tables)
  metrics <- summarise_datasets(tables)
  list(datasets = tables, metrics = metrics)
}
