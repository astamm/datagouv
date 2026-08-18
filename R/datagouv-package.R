#' datagouv: Tools to download and explore datasets from the French open data
#' platform
#'
#' This package provides a small client for the public API of
#' [data.gouv.fr](https://www.data.gouv.fr), the French government's open data
#' platform. It lets you list the published datasets, download their tabular
#' resources and compute summary metrics (file weight, number of columns,
#' missing-value rates, ...). Requests are built on top of the `httr2` package.
#'
#' @keywords internal
#' @importFrom dplyr bind_rows
#' @importFrom httr2 req_error
#' @importFrom httr2 req_perform
#' @importFrom httr2 req_retry
#' @importFrom httr2 req_timeout
#' @importFrom httr2 req_url_path_append
#' @importFrom httr2 req_url_query
#' @importFrom httr2 req_user_agent
#' @importFrom httr2 request
#' @importFrom httr2 resp_body_json
#' @importFrom httr2 resp_body_raw
#' @importFrom httr2 resp_status
#' @importFrom purrr imap
#' @importFrom purrr map
#' @importFrom purrr map_chr
#' @importFrom purrr map_lgl
#' @importFrom readr read_csv
#' @importFrom readr read_delim
#' @importFrom readxl read_excel
#' @importFrom stats setNames
#' @importFrom tibble as_tibble
#' @importFrom tibble tibble
#' @importFrom tidyr drop_na
#' @importFrom utils head
#' @importFrom utils object.size
"_PACKAGE"
