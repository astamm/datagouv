# Tests for the internal utility helpers.

# Build a fake httr2 response carrying a JSON body.
fake_json_response <- function(json, status = 200) {
  httr2::response(
    status_code = status,
    url = "https://example.org/",
    headers = list("Content-Type" = "application/json"),
    body = charToRaw(json)
  )
}

# Mock req_perform so the bare calls in the package code are intercepted.
# The package calls `req_perform()` (resolved via @importFrom) so mocking the
# package-namespace binding replaces it.
local_mock_req_perform <- function(response_fun, env = parent.frame()) {
  testthat::local_mocked_bindings(req_perform = response_fun, .env = env)
}

test_that("%||% returns the fallback when the value is NULL", {
  expect_equal(NULL %||% "fallback", "fallback")
  expect_equal(1 %||% "fallback", 1)
})

test_that("req_data_gouv() sets a timeout and bounded retries", {
  req <- req_data_gouv(request("https://example.org"))

  expect_equal(req$options$timeout_ms, 30000)
  expect_equal(req$policies$retry_max_tries, 3)
  expect_equal(req$policies$retry_max_wait, 8)
  expect_true(req$policies$retry_on_failure)
})

test_that("req_data_gouv() treats only gateway 429/5xx as transient", {
  is_transient <- req_data_gouv(request("https://example.org"))$policies$retry_is_transient

  transient <- c(429, 500, 502, 503, 504)
  expect_true(all(sapply(transient, function(st) {
    is_transient(httr2::response(status_code = st, url = "https://example.org"))
  })))

  # Non-transient statuses (including 4xx client errors) must not be retried.
  not_transient <- c(200, 400, 404, 408, 425)
  expect_false(any(sapply(not_transient, function(st) {
    is_transient(httr2::response(status_code = st, url = "https://example.org"))
  })))
})

test_that("download_resource() routes through req_data_gouv() hardening", {
  local_mock_req_perform(function(req, ...) {
    httr2::response(
      status_code = 200,
      url = "https://example.org/data.csv",
      headers = list("Content-Type" = "text/csv"),
      body = charToRaw("a,b\n1,2\n")
    )
  })

  path <- download_resource(mock_resource("csv"))

  expect_match(path, "\\.csv$")
  expect_true(file.exists(path))
  unlink(path)
})

test_that("fetch_datasets_page() parses the JSON response", {
  local_mock_req_perform(function(req, ...) {
    fake_json_response('{"data": [{"title": "A"}], "next_page": null, "total": 1}')
  })

  body <- fetch_datasets_page(page = 1, page_size = 20)

  expect_equal(body$total, 1)
  expect_equal(body$data[[1]]$title, "A")
})

test_that("fetch_datasets_page() forwards the search query", {
  seen_query <- NULL
  local_mock_req_perform(function(req, ...) {
    seen_query <<- httr2::url_parse(req$url)$query$q
    fake_json_response('{"data": [], "next_page": null, "total": 0}')
  })

  fetch_datasets_page(page = 1, page_size = 20, q = "vélo")

  expect_equal(seen_query, "vélo")
})

test_that("fetch_all_datasets() stops once n datasets are collected", {
  # Simulate a server that honours page_size: each call returns at most
  # page_size items from a shared (large) pool.
  titles <- letters[1:20]
  requested_sizes <- integer()
  local_mocked_bindings(
    fetch_datasets_page = function(page, page_size, q = NULL) {
      requested_sizes <<- c(requested_sizes, page_size)
      start <- (page - 1) * page_size + 1
      end <- min(page * page_size, length(titles))
      list(
        data = lapply(titles[start:end], mock_dataset),
        next_page = if (end < length(titles)) paste0("page", page + 1) else NULL
      )
    }
  )

  out <- fetch_all_datasets(page_size = 100, n = 5)

  expect_length(out, 5)
  expect_equal(purrr::map_chr(out, ~ .x$title), letters[1:5])
  # The first request is capped at n (5), and no further page is fetched.
  expect_equal(requested_sizes, 5)
})

test_that("fetch_all_datasets() fetches all pages when n is Inf", {
  titles <- letters[1:7]
  local_mocked_bindings(
    fetch_datasets_page = function(page, page_size, q = NULL) {
      start <- (page - 1) * page_size + 1
      end <- min(page * page_size, length(titles))
      list(
        data = lapply(titles[start:end], mock_dataset),
        next_page = if (end < length(titles)) paste0("page", page + 1) else NULL
      )
    }
  )

  out <- fetch_all_datasets(page_size = 3, n = Inf)

  expect_length(out, 7)
  expect_equal(purrr::map_chr(out, ~ .x$title), letters[1:7])
})

test_that("fetch_all_datasets() honors the search query", {
  seen <- list()
  local_mocked_bindings(
    fetch_datasets_page = function(page, page_size, q = NULL) {
      seen <<- c(seen, list(q))
      list(data = list(mock_dataset(title = "A")), next_page = NULL)
    }
  )

  fetch_all_datasets(page_size = 100, q = "vélo", n = 1000)

  expect_equal(seen, list("vélo"))
})

test_that("fetch_all_datasets() pages until there is no next page", {
  pages <- list(
    list(data = list(mock_dataset(title = "A")), next_page = "page2"),
    list(data = list(mock_dataset(title = "B")), next_page = NULL)
  )
  local_mocked_bindings(
    fetch_datasets_page = function(page, page_size, q = NULL) pages[[page]]
  )

  out <- fetch_all_datasets()

  expect_length(out, 2)
  expect_equal(purrr::map_chr(out, ~ .x$title), c("A", "B"))
})

test_that("fetch_all_datasets() stops on an empty page", {
  local_mocked_bindings(
    fetch_datasets_page = function(page, page_size, q = NULL) {
      list(data = list(), next_page = NULL)
    }
  )

  out <- fetch_all_datasets()

  expect_length(out, 0)
})

test_that("find_dataset() returns the exact-matching title", {
  local_mock_req_perform(function(req, ...) {
    fake_json_response(
      '{"data": [{"title": "Not it"}, {"title": "Target dataset"}]}'
    )
  })

  out <- find_dataset("Target dataset")

  expect_equal(out$title, "Target dataset")
})

test_that("find_dataset() errors when no title matches exactly", {
  local_mock_req_perform(function(req, ...) {
    fake_json_response('{"data": [{"title": "Something else"}]}')
  })

  expect_snapshot(error = TRUE, find_dataset("Does not exist"))
})

test_that("pick_resource() chooses the first supported resource", {
  dataset <- mock_dataset(resources = list(
    mock_resource("pdf"),
    mock_resource("csv", title = "data.csv")
  ))

  out <- pick_resource(dataset)

  expect_equal(out$format, "csv")
})

test_that("pick_resource() errors when the dataset has no resources", {
  dataset <- mock_dataset(resources = list())

  expect_snapshot(error = TRUE, pick_resource(dataset))
})

test_that("pick_resource() errors when no resource is supported", {
  dataset <- mock_dataset(resources = list(mock_resource("pdf")))

  expect_snapshot(error = TRUE, pick_resource(dataset))
})

local_csv_path <- function(ext, lines) {
  path <- tempfile(fileext = paste0(".", ext))
  writeLines(lines, path)
  path
}

test_that("read_resource() parses a CSV resource", {
  local_mocked_bindings(
    download_resource = function(resource) local_csv_path("csv", c("a,b", "1,x", "2,y"))
  )

  out <- read_resource(mock_resource("csv"))

  expect_named(out, c("a", "b"))
  expect_equal(nrow(out), 2)
})

test_that("read_resource() supports tsv and txt resources", {
  local_mocked_bindings(
    download_resource = function(resource) local_csv_path("tsv", c("a\tb", "1\tx"))
  )

  out <- read_resource(mock_resource("tsv"))

  expect_named(out, c("a", "b"))
  expect_equal(nrow(out), 1)
})

test_that("read_resource() parses a txt resource with a tab delim", {
  local_mocked_bindings(
    download_resource = function(resource) local_csv_path("txt", c("a\tb", "1\tx"))
  )

  out <- read_resource(mock_resource("txt"))

  expect_named(out, c("a", "b"))
  expect_equal(nrow(out), 1)
})

test_that("read_resource() parses an xlsx resource", {
  skip_if_not_installed("writexl")
  local_mocked_bindings(
    download_resource = function(resource) {
      path <- tempfile(fileext = ".xlsx")
      writexl::write_xlsx(data.frame(a = 1:2, b = c("x", "y")), path)
      path
    }
  )

  out <- read_resource(mock_resource("xlsx"))

  expect_named(out, c("a", "b"))
  expect_equal(nrow(out), 2)
})

test_that("read_resource() errors on unsupported formats", {
  local_mocked_bindings(
    download_resource = function(resource) local_csv_path("csv", c("a", "1"))
  )

  expect_snapshot(error = TRUE, read_resource(mock_resource("pdf")))
})

test_that("download_resource() writes the expected bytes based on format", {
  local_mock_req_perform(function(req, ...) {
    httr2::response(
      status_code = 200,
      url = "https://example.org/data.csv",
      headers = list("Content-Type" = "text/csv"),
      body = charToRaw("a,b\n1,2\n")
    )
  })

  path <- download_resource(mock_resource("csv"))

  expect_match(path, "\\.csv$")
  expect_true(file.exists(path))
  unlink(path)
})

test_that("download_resource() falls back to .bin when the format is missing", {
  res <- mock_resource(format = NULL)
  local_mock_req_perform(function(req, ...) {
    httr2::response(
      status_code = 200,
      url = "https://example.org/data",
      headers = list("Content-Type" = "application/octet-stream"),
      body = charToRaw("hello")
    )
  })

  path <- download_resource(res)

  expect_match(path, "\\.bin$")
  expect_true(file.exists(path))
  unlink(path)
})
