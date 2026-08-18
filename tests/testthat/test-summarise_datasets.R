test_that("summarise_datasets() summarises a named list of tibbles", {
  out <- summarise_datasets(datasets = list(iris = iris, mtcars = mtcars))

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2)
  expect_named(
    out,
    c("dataset", "size_kb", "n_vars", "n_numeric", "n_non_numeric",
      "n_rows", "prop_missing")
  )
  expect_equal(out$dataset, c("iris", "mtcars"))
  expect_equal(out$n_rows, c(150, 32))
})

test_that("summarise_datasets() downloads datasets from names when given a character vector", {
  local_mocked_bindings(
    get_dataset = function(name, remove_na = FALSE) {
      data.frame(x = 1, y = "v")
    }
  )

  out <- summarise_datasets(datasets = c("A", "B"))

  expect_equal(out$dataset, c("A", "B"))
  expect_equal(out$n_vars, c(2, 2))
})

test_that("summarise_datasets() uses the first n datasets by default", {
  local_mocked_bindings(
    list_datasets = function(q = NULL, n = 1000) utils::head(paste0("ds", 1:10), n),
    get_dataset = function(name, remove_na = FALSE) {
      data.frame(x = 1, y = "v")
    }
  )

  out <- summarise_datasets(n = 3)

  expect_equal(out$dataset, c("ds1", "ds2", "ds3"))
})

test_that("summarise_datasets() returns an empty tibble for an empty list", {
  out <- summarise_datasets(datasets = list())

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0)
})

test_that("summarise_datasets() errors on invalid input", {
  expect_snapshot(error = TRUE, summarise_datasets(datasets = 42))
})
