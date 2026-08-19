test_that("dg_pull_dataset() downloads and formats a dataset", {
  local_mocked_bindings(
    find_dataset = function(id) mock_dataset(title = id, id = id),
    read_first_parseable_resource = function(dataset) {
      list(data = mock_csv_data(), resource = mock_resource("csv"))
    }
  )

  out <- dg_pull_dataset("aaaaaaaaaaaaaaaaaaaaaaaa")

  # The result is always a named list of tibbles (a single element when the
  # resource is not a ZIP).
  expect_type(out, "list")
  expect_length(out, 1)
  expect_s3_class(out[[1]], "tbl_df")
  expect_equal(nrow(out[[1]]), 3)
  expect_named(out[[1]], c("a", "b", ".id"))
})

test_that("dg_pull_dataset() forwards remove_na to format_tibble()", {
  local_mocked_bindings(
    find_dataset = function(id) mock_dataset(title = id, id = id),
    read_first_parseable_resource = function(dataset) {
      list(data = mock_csv_data(), resource = mock_resource("csv"))
    }
  )

  out <- dg_pull_dataset("aaaaaaaaaaaaaaaaaaaaaaaa", remove_na = TRUE)

  expect_equal(nrow(out[[1]]), 2)
})

test_that("dg_pull_dataset() preserves each table of a ZIP resource", {
  local_mocked_bindings(
    find_dataset = function(id) mock_dataset(title = id, id = id),
    read_first_parseable_resource = function(dataset) {
      list(
        data = list(
          "data.csv" = mock_csv_data(),
          "notes.tsv" = data.frame(c = 1, d = "x")
        ),
        resource = mock_resource("zip")
      )
    }
  )

  out <- dg_pull_dataset("aaaaaaaaaaaaaaaaaaaaaaaa")

  expect_type(out, "list")
  expect_named(out, c("data.csv", "notes.tsv"))
  expect_s3_class(out$`data.csv`, "tbl_df")
  expect_s3_class(out$notes.tsv, "tbl_df")
  expect_equal(nrow(out$`data.csv`), 3)
})

test_that("dg_pull_dataset() skips a resource that fails to parse", {
  # The first candidate cannot be read as a table; the second one can.
  local_mocked_bindings(
    find_dataset = function(id) mock_dataset(title = id, id = id),
    read_first_parseable_resource = function(dataset) {
      list(data = mock_csv_data(), resource = mock_resource("json"))
    }
  )

  out <- dg_pull_dataset("aaaaaaaaaaaaaaaaaaaaaaaa")

  expect_length(out, 1)
  expect_s3_class(out[[1]], "tbl_df")
  expect_equal(nrow(out[[1]]), 3)
})
