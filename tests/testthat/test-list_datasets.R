test_that("list_datasets() returns the titles of all datasets", {
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) {
      list(
        mock_dataset(title = "A"),
        mock_dataset(title = "B"),
        mock_dataset(title = "C")
      )
    }
  )

  out <- list_datasets()

  expect_type(out, "character")
  expect_equal(out, c("A", "B", "C"))
})

test_that("list_datasets() returns an empty vector when the API is empty", {
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) list()
  )

  out <- list_datasets()

  expect_type(out, "character")
  expect_length(out, 0)
})

test_that("list_datasets() coerce missing titles to NA", {
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) {
      list(mock_dataset(title = "A"), mock_dataset(title = NULL))
    }
  )

  out <- list_datasets()

  expect_equal(out, c("A", NA))
})

test_that("list_datasets() forwards the search query and the limit", {
  seen <- NULL
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) {
      seen <<- list(q = q, n = n)
      list(mock_dataset(title = "Cyclable"))
    }
  )

  out <- list_datasets(q = "vélo", n = 7)

  expect_equal(out, "Cyclable")
  expect_equal(seen$q, "vélo")
  expect_equal(seen$n, 7)
})
