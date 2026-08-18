# Internal helpers for the datagouv package.
# These functions are not exported.

# Base URL of the data.gouv public API.
datagouv_base_url <- function() {
  "https://www.data.gouv.fr/api/1/"
}

# Build a configured httr2 request against the data.gouv API.
# Adds a polite user agent, a timeout, retry on transient errors and a
# friendly error message extracted from the JSON error body.
#
# data.gouv's API (behind nginx) intermittently answers 5xx for otherwise
# valid requests, so we retry genuinely transient statuses (429 and 5xx).
# 4xx responses are NOT retried: a real 400/404/408 is a permanent
# condition, and re-sending it with backoff would multiply the latency of an
# already-slow page crawl for no gain. Low-level failures (timeouts, dropped
# connections, DNS) are retried too, but within a tight global budget so a
# flaky endpoint cannot stall the whole enumeration for minutes.
req_data_gouv <- function(req) {
  req |>
    req_user_agent("datagouv R package (https://github.com/stamm-a/datagouv)") |>
    # A hung reply must not block get_dataset() indefinitely.
    req_timeout(seconds = 30) |>
    req_error(
      is_error = function(resp) resp_status(resp) >= 400,
      body = function(resp) {
        tryCatch(
          resp_body_json(resp)$message,
          error = function(e) ""
        )
      }
    ) |>
    req_retry(
      is_transient = function(resp) {
        resp_status(resp) %in% c(429, 500, 502, 503, 504)
      },
      # Also retry low-level failures (timeouts, dropped connections, DNS).
      retry_on_failure = TRUE,
      max_tries = 3,
      # Caps total retry time so a failing endpoint cannot stall the call
      # for minutes on end.
      max_seconds = 8
    )
}

# Fetch a single page of datasets from the API.
fetch_datasets_page <- function(page, page_size, q = NULL) {
  req <- req_data_gouv(request(datagouv_base_url())) |>
    req_url_path_append("datasets") |>
    req_url_query(page = page, page_size = page_size, format = c("csv", "xlsx", "tsv", "txt"), .multi = "explode")
  if (!is.null(q)) {
    req <- req_url_query(req, q = q)
  }
  req |>
    req_perform() |>
    resp_body_json()
}

# Fetch datasets objects, following pagination until the last page or until
# `n` datasets have been collected (whichever comes first).
#
# `q` is an optional full-text query forwarded to the API, so the search is
# done server-side instead of downloading and filtering the whole catalog.
# `n` bounds the number of datasets returned; the default caps the work so a
# caller cannot accidentally trigger a 700+ request crawl of the entire
# platform. Pass `n = Inf` to enumerate everything.
fetch_all_datasets <- function(page_size = 100, q = NULL, n = 1000) {
  datasets <- list()
  page <- 1
  repeat {
    if (length(datasets) >= n) {
      break
    }
    remaining <- n - length(datasets)
    this_size <- min(page_size, remaining)
    body <- fetch_datasets_page(page, this_size, q = q)
    items <- body$data
    if (length(items) == 0) {
      break
    }
    datasets <- c(datasets, items)
    if (is.null(body$next_page)) {
      break
    }
    page <- page + 1
  }
  datasets
}

# Test whether a string is a data.gouv dataset identifier (a MongoDB
# ObjectId: 24 hexadecimal characters).
is_dataset_id <- function(x) {
  !is.na(x) && grepl("^[0-9a-fA-F]{24}$", x)
}

# Make the names of a named list unique by appending each element's value to
# names that are shared by several elements. This keeps human-readable titles
# as labels while guaranteeing every row remains distinguishable even when
# titles collide (the values, typically dataset identifiers, are unique).
uniquify_names <- function(x) {
  nm <- names(x)
  dup <- duplicated(nm) | duplicated(nm, fromLast = TRUE)
  nm[dup] <- paste0(nm[dup], " [", x[dup], "]")
  names(x) <- nm
  x
}

# Fetch a single dataset object by its identifier.
#
# Unlike title-based lookup (which searches and filters, and can be ambiguous
# when titles collide), identifiers are unique and stable, so a direct GET on
# the `/datasets/{id}/` endpoint always returns exactly the right dataset.
fetch_dataset <- function(id) {
  req_data_gouv(request(datagouv_base_url())) |>
    req_url_path_append("datasets", id) |>
    req_perform() |>
    resp_body_json()
}

# Find a dataset object by its identifier, or, as a fallback kept for
# backwards compatibility, by its exact title.
find_dataset <- function(id) {
  if (is_dataset_id(id)) {
    return(fetch_dataset(id))
  }
  body <- req_data_gouv(request(datagouv_base_url())) |>
    req_url_path_append("datasets") |>
    req_url_query(q = id, page_size = 50) |>
    req_perform() |>
    resp_body_json()

  hits <- Filter(function(d) identical(d$title, id), body$data)
  if (length(hits) == 0) {
    stop(
      "No dataset titled '", id,
      "' was found on data.gouv.fr. Check the name with list_datasets().",
      call. = FALSE
    )
  }
  hits[[1]]
}

# Resource formats that can be parsed into a table.
supported_formats <- function() {
  c("csv", "csv.gz", "tsv", "txt", "xlsx", "json")
}

# Pick the first resource of a dataset whose format can be parsed to a table.
pick_resource <- function(dataset) {
  resources <- dataset$resources
  if (length(resources) == 0) {
    stop(
      "Dataset '", dataset$title, "' has no resources.",
      call. = FALSE
    )
  }
  for (res in resources) {
    fmt <- tolower(res$format %||% "")
    if (fmt %in% supported_formats()) {
      return(res)
    }
  }
  stop(
    "Dataset '", dataset$title,
    "' has no resource in a supported format ",
    "(CSV, TSV, TXT, XLSX or JSON).",
    call. = FALSE
  )
}

# `x %||% y` returns x unless x is NULL, in which case it returns y.
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Guess the field separator of a delimited text file by counting candidate
# delimiters in the first lines. The extension (.csv, .txt, ...) says little
# about the actual delimiter, so we sniff it from the data. Candidates are
# tried in a fixed order and the one with the most occurrences wins; ties are
# broken by that order (tab > semicolon > comma > pipe > colon).
guess_delimiter <- function(path, n = 20) {
  lines <- readLines(path, n = n, warn = FALSE)
  candidates <- c("\t", ";", ",", "|", ":")
  counts <- vapply(candidates, function(d) {
    sum(lengths(regmatches(lines, gregexpr(d, lines, fixed = TRUE))))
  }, integer(1))
  candidates[which.max(counts)]
}

# Parse a JSON resource into a data frame. data.gouv JSON files come in two
# shapes: an array of objects (one row per object) or newline-delimited JSON
# (one object per line); both are handled, and a bare single object is wrapped
# into a one-row table so the result is always a data frame. A JSON *array* is
# read with fromJSON(); when that fails the file is newline-delimited JSON
# (concatenated objects), which fromJSON() rejects but stream_in() reads.
read_json_file <- function(path) {
  out <- tryCatch(
    fromJSON(path, flatten = TRUE),
    error = function(e) NULL
  )
  if (is.data.frame(out)) {
    return(out)
  }
  if (is.list(out) && !is.null(names(out))) {
    # Single object (or nested object) -> one row.
    return(tibble::as_tibble(out))
  }
  # fromJSON() returned nothing (empty file) or threw: newline-delimited JSON.
  stream_in(file(path), verbose = FALSE)
}

# Download a resource and parse it into a data frame.
read_resource <- function(resource) {
  fmt <- tolower(resource$format %||% "")
  # Guard against formats pick_resource() should have already filtered out.
  if (!fmt %in% supported_formats()) {
    stop("Unsupported format: ", resource$format, call. = FALSE)
  }
  path <- download_resource(resource)
  on.exit(unlink(path))

  if (fmt == "xlsx") {
    return(read_excel(path))
  }
  if (fmt == "json") {
    return(read_json_file(path))
  }
  # Every other supported format is delimited text (CSV, CSV.GZ, TSV or TXT).
  delim <- guess_delimiter(path)
  if (delim == "\t") {
    return(read_tsv(path))
  }
  if (delim == ";") {
    # European-style CSV: semicolon field separator with a comma decimal mark.
    return(read_csv2(path))
  }
  if (delim == ",") {
    return(read_csv(path))
  }
  # Any other delimiter (e.g. pipe or colon): use the generic reader.
  read_delim(path, delim = delim)
}

# Download a resource to a temporary file and return its path.
# The request goes through `req_data_gouv()` so it benefits from the same
# timeout and retry handling as the API calls (the resources are served
# from a static CDN that can also be slow or flaky).
download_resource <- function(resource) {
  path <- tempfile(
    pattern = "datagouv-",
    fileext = paste0(".", resource$format %||% "bin")
  )
  req_data_gouv(request(resource$url)) |>
    req_perform() |>
    resp_body_raw() |>
    writeBin(path)
  path
}
