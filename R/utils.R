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
  httr2::req_retry(
    httr2::req_error(
      httr2::req_timeout(
        # A hung reply must not block dg_pull_dataset() indefinitely.
        httr2::req_user_agent(
          req,
          "datagouv R package (https://github.com/stamm-a/datagouv)"
        ),
        seconds = 30
      ),
      is_error = function(resp) httr2::resp_status(resp) >= 400,
      body = function(resp) {
        tryCatch(
          httr2::resp_body_json(resp)$message,
          error = function(e) ""
        )
      }
    ),
    is_transient = function(resp) {
      httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504)
    },
    # Also retry low-level failures (timeouts, dropped connections, DNS).
    retry_on_failure = TRUE,
    max_tries = 3,
    # Caps total retry time so a failing endpoint cannot stall the call
    # for minutes on end.
    max_seconds = 8
  )
}

# Perform a prepared request. A thin internal wrapper around
# httr2::req_perform() so callers avoid @importFrom directives while keeping a
# single, easily mockable seam for tests.
http_perform <- function(req) {
  httr2::req_perform(req)
}

# Fetch a single page of datasets from the API.
fetch_datasets_page <- function(page, page_size, q = NULL) {
  req <- httr2::req_url_query(
    httr2::req_url_path_append(
      req_data_gouv(httr2::request(datagouv_base_url())),
      "datasets"
    ),
    page = page,
    page_size = page_size,
    # Restrict the catalog to data.gouv's official tabular formats so that
    # every listed dataset is (in principle) openable as a table.
    format = catalog_formats(),
    .multi = "explode"
  )
  if (!is.null(q)) {
    req <- httr2::req_url_query(req, q = q)
  }
  httr2::resp_body_json(http_perform(req))
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
  httr2::resp_body_json(
    http_perform(
      httr2::req_url_path_append(
        req_data_gouv(httr2::request(datagouv_base_url())),
        "datasets", id
      )
    )
  )
}

# Find a dataset object by its identifier, or, as a fallback kept for
# backwards compatibility, by its exact title.
find_dataset <- function(id) {
  if (is_dataset_id(id)) {
    return(fetch_dataset(id))
  }
  body <- httr2::resp_body_json(
    http_perform(
      httr2::req_url_query(
        httr2::req_url_path_append(
          req_data_gouv(httr2::request(datagouv_base_url())),
          "datasets"
        ),
        q = id,
        page_size = 50
      )
    )
  )

  hits <- Filter(function(d) identical(d$title, id), body$data)
  if (length(hits) == 0) {
    stop(
      "No dataset titled '", id,
      "' was found on data.gouv.fr. Check the name with dg_list_datasets().",
      call. = FALSE
    )
  }
  hits[[1]]
}

# Resource formats that can be parsed into a table. A "zip" resource is
# itself unreadable, but its archive can hold files in any of the other
# supported formats, so it is included here so that a ZIP is picked up as a
# candidate and read_resource() unpacks it.
#
# The first block is the official set of tabular formats data.gouv.fr indexes
# in its tabular service (csv, csv.gz, xls, xlsx, parquet). The full vector is
# wider because direct pulls (dg_pull_dataset()/dg_refetch()) still parse
# trivially-tabular TSV/TXT and JSON that data.gouv does not guarantee is
# tabular at catalog time.
supported_formats <- function() {
  c("zip", "csv", "csv.gz", "xls", "xlsx", "parquet", "tsv", "txt", "json")
}

# Formats a dataset must contain at least one resource of to be listed in the
# discovery catalog. This is data.gouv's own set of tabular formats (see
# https://www.data.gouv.fr/dataservices/api-tabulaire-data-gouv-fr-beta); it is
# deliberately narrower than supported_formats() because only these are
# guaranteed tabular by the platform.
catalog_formats <- function() {
  c("csv", "csv.gz", "xls", "xlsx", "parquet")
}

# Whether a resource points at a declared data schema. data.gouv attaches the
# schema as a pointer (a `schema` node carrying `name` and/or `url`); the actual
# `fields` documentation lives in the referenced schema document on
# schema.data.gouv.fr. NULL fields mean no schema has been declared.
resource_has_schema <- function(resource) {
  schema <- resource$schema %||% list()
  !is.null(schema$name) || !is.null(schema$url)
}

# Walk a dataset's tabular candidates in declared order and return the first
# that actually parses into a table.
#
# data.gouv declares a format on every resource, but the declaration is not
# always reliable: a resource tagged `json` can in practice serve an API
# metadata document (e.g. `{"links": ..., "dataset": ...}`) rather than tabular
# data, and such a resource cannot be read as a table. Because real
# parseability is only knowable after downloading, we try each candidate in
# order and keep the first that succeeds. If none parse, we error naming the
# dataset and the first failure so the user is not left guessing which resource
# was at fault.
read_first_parseable_resource <- function(dataset) {
  candidates <- Filter(
    function(r) tolower(r$format %||% "") %in% supported_formats(),
    dataset$resources %||% list()
  )
  if (length(candidates) == 0) {
    supported <- paste(supported_formats(), collapse = ", ")
    stop(
      "Dataset '", dataset$title,
      "' has no resource in a supported format (", supported, ").",
      call. = FALSE
    )
  }
  first_error <- NULL
  for (res in candidates) {
    data <- tryCatch(read_resource(res), error = function(e) e)
    if (!inherits(data, "error")) {
      return(list(data = data, resource = res))
    }
    if (is.null(first_error)) {
      first_error <- data
    }
  }
  stop(
    "None of the ", length(candidates), " tabular resource(s) of dataset '",
    dataset$title, "' could be parsed into a table. First failure: ",
    conditionMessage(first_error),
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
    jsonlite::fromJSON(path, flatten = TRUE),
    error = function(e) NULL
  )
  if (is.data.frame(out)) {
    return(out)
  }
  if (is.list(out) && !is.null(names(out))) {
    # A top-level object is normally a single row, e.g. {"a": 1, "b": "x"}.
    # But a nested object with list-valued or variable-length fields (such as
    # an API metadata document describing a resource) is not a table. Fail with
    # a clear, actionable message rather than let tibble::as_tibble() raise a
    # cryptic "incompatible sizes" error.
    return(tryCatch(
      tibble::as_tibble(out),
      error = function(e) {
        stop(
          "JSON object is not tabular data: ", conditionMessage(e), ". ",
          "This resource declares `json` but does not contain a table (it is ",
          "likely an API metadata document). Try another resource of the ",
          "dataset, e.g. via dg_list_datasets() or dg_refetch().",
          call. = FALSE
        )
      }
    ))
  }
  # fromJSON() returned nothing (empty file) or threw: newline-delimited JSON.
  jsonlite::stream_in(file(path), verbose = FALSE)
}

# Parse a local file of a known supported format into a data frame. The file
# must already be on disk; callers are responsible for downloading (or
# extracting) it and for cleaning it up.
parse_resource_file <- function(path, fmt) {
  if (fmt == "xlsx" || fmt == "xls") {
    return(readxl::read_excel(path))
  }
  if (fmt == "parquet") {
    return(nanoparquet::read_parquet(path))
  }
  if (fmt == "json") {
    return(read_json_file(path))
  }
  # Every other supported format is delimited text (CSV, CSV.GZ, TSV or TXT).
  delim <- guess_delimiter(path)
  if (delim == "\t") {
    return(readr::read_tsv(path))
  }
  if (delim == ";") {
    # European-style CSV: semicolon field separator with a comma decimal mark.
    return(readr::read_csv2(path))
  }
  if (delim == ",") {
    return(readr::read_csv(path))
  }
  # Any other delimiter (e.g. pipe or colon): use the generic reader.
  readr::read_delim(path, delim = delim)
}

# Map a file path to a supported resource format by its extension, or NA if
# the extension is not one of the supported formats. Multi-dot formats such
# as ".csv.gz" are matched as a whole so they are not confused with a plain
# ".gz", which cannot be parsed on its own.
format_from_path <- function(path) {
  sup <- supported_formats()
  hit <- sup[endsWith(tolower(basename(path)), paste0(".", sup))]
  if (length(hit) == 0) NA_character_ else hit[[1]]
}

# Parse a ZIP resource: extract its contents to a temporary directory, then
# parse every contained file whose extension maps to a supported format,
# skipping the rest. The result is a named list with one element per parsed
# file (names made unique in case two files share a base name); it is empty
# when the archive holds nothing readable.
read_zip_resource <- function(resource) {
  zip <- download_resource(resource)
  on.exit(unlink(zip))
  dir <- tempfile(pattern = "datagouv-zip-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  utils::unzip(zip, exdir = dir)

  files <- list.files(dir, full.names = TRUE, recursive = TRUE)
  fmt <- vapply(files, format_from_path, character(1))
  keep <- !is.na(fmt)
  parsed <- Map(parse_resource_file, files[keep], fmt[keep])
  names(parsed) <- uniquify_names(basename(files[keep]))
  parsed
}

# Compose the stable, unique identifier of a parsed table. Format:
#   "<dataset_id>::<resource_id>"        for a single-file resource
#   "<dataset_id>::<resource_id>::<file>" for a file inside a ZIP
# `::` never appears in dataset ids (24-hex), resource ids (UUIDs) or file
# base names, so the delimiter is unambiguous.
compose_table_id <- function(dataset_id, resource_id, file = NULL) {
  id <- paste(dataset_id, resource_id, sep = "::")
  if (!is.null(file)) {
    id <- paste(id, file, sep = "::")
  }
  id
}

# Split a composed table id into its (dataset, resource, file) parts.
# Returns a named list; `file` is NULL when absent. Errors on a malformed id.
parse_table_id <- function(id) {
  parts <- strsplit(id, "::", fixed = TRUE)[[1]]
  if (length(parts) < 2 || length(parts) > 3) {
    stop(
      "Invalid table id '", id, "': expected '<dataset>::<resource>' or ",
      "'<dataset>::<resource>::<file>'.", call. = FALSE
    )
  }
  if (!is_dataset_id(parts[[1]])) {
    stop("Invalid table id '", id, "': '", parts[[1]],
      "' is not a dataset identifier.", call. = FALSE
    )
  }
  list(
    dataset_id = parts[[1]],
    resource_id = parts[[2]],
    file = if (length(parts) == 3) parts[[3]] else NULL
  )
}

# Parse a single named file out of a ZIP resource and return its data frame,
# skipping nothing else. Used by dg_refetch() to re-read exactly one table.
# `name` is a base file name within the archive.
read_one_zip_file <- function(resource, name) {
  zip <- download_resource(resource)
  on.exit(unlink(zip))
  dir <- tempfile(pattern = "datagouv-zip-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  utils::unzip(zip, exdir = dir)
  path <- file.path(dir, name)
  fmt <- format_from_path(path)
  if (is.na(fmt)) {
    stop("File '", name, "' inside the ZIP is not in a supported format.",
      call. = FALSE
    )
  }
  parse_resource_file(path, fmt)
}

# Download a resource and parse it into a data frame. ZIP resources are
# unpacked first: each contained file in a supported format becomes one
# element of the returned named list.
read_resource <- function(resource) {
  fmt <- tolower(resource$format %||% "")
  if (fmt == "zip") {
    return(read_zip_resource(resource))
  }
  # Guard against formats the candidate filter should have already removed.
  if (!fmt %in% supported_formats()) {
    stop("Unsupported format: ", resource$format, call. = FALSE)
  }
  path <- download_resource(resource)
  on.exit(unlink(path))
  parse_resource_file(path, fmt)
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
  writeBin(
    httr2::resp_body_raw(
      http_perform(req_data_gouv(httr2::request(resource$url)))
    ),
    path
  )
  path
}
