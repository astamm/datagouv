test_that("wrapper_datasets() returns raw datasets and metrics", {
  local_mocked_bindings(
    dg_pull_dataset = function(id, remove_na = FALSE) {
      data.frame(x = 1, y = "v")
    },
    summarise_datasets = function(datasets) {
      tibble::tibble(
        dataset = names(datasets),
        size_kb = 1,
        n_vars = 2,
        n_numeric = 1,
        n_non_numeric = 1,
        n_rows = 1,
        prop_missing = 0
      )
    }
  )

  out <- wrapper_datasets(c("aaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbb"))

  expect_type(out, "list")
  expect_named(out, c("datasets", "metrics"))
  expect_named(out$datasets, c("aaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbb"))
  expect_equal(nrow(out$datasets$aaaaaaaaaaaaaaaaaaaaaaaa), 1)
  expect_equal(out$metrics$dataset, c("aaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbb"))
})

test_that("wrapper_datasets() forwards remove_na to dg_pull_dataset()", {
  seen <- c()
  local_mocked_bindings(
    dg_pull_dataset = function(id, remove_na = FALSE) {
      seen <<- c(seen, remove_na)
      data.frame(x = 1)
    },
    summarise_datasets = function(datasets) tibble::tibble(dataset = "A")
  )

  wrapper_datasets("aaaaaaaaaaaaaaaaaaaaaaaa", remove_na = TRUE)

  expect_true(seen[[1]])
})
