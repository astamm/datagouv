test_that("dg_list_datasets() returns a tibble with the expected columns", {
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) {
      list(
        mock_dataset(title = "A", id = "a1"),
        mock_dataset(title = "B", id = "b2"),
        mock_dataset(title = "C", id = "c3")
      )
    }
  )

  out <- dg_list_datasets()

  expect_s3_class(out, "tbl_df")
  expect_named(out, c("title", "id", "description", "slug"))
  expect_equal(out$title, c("A", "B", "C"))
  expect_equal(out$id, c("a1", "b2", "c3"))
})

test_that("dg_list_datasets() returns an empty tibble when the API is empty", {
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) list()
  )

  out <- dg_list_datasets()

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0)
})

test_that("dg_list_datasets() coerces missing fields to NA", {
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) {
      list(
        mock_dataset(title = "A", id = "a1"),
        list(id = "b2", slug = "b", description = NULL)
      )
    }
  )

  out <- dg_list_datasets()

  expect_equal(out$title, c("A", NA))
  expect_equal(out$id, c("a1", "b2"))
})

test_that("dg_list_datasets() forwards the search query and the limit", {
  seen <- NULL
  local_mocked_bindings(
    fetch_all_datasets = function(page_size = 100, q = NULL, n = 1000) {
      seen <<- list(q = q, n = n)
      list(mock_dataset(title = "Cyclable", id = "c1"))
    }
  )

  out <- dg_list_datasets(q = "vélo", n = 7)

  expect_equal(out$title, "Cyclable")
  expect_equal(seen$q, "vélo")
  expect_equal(seen$n, 7)
})
