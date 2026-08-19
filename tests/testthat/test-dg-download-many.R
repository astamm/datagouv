test_that("dg_download_many() returns raw datasets and metrics", {
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

  out <- dg_download_many(c("aaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbb"))

  expect_type(out, "list")
  expect_named(out, c("datasets", "metrics"))
  expect_named(out$datasets, c("aaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbb"))
  expect_equal(nrow(out$datasets$aaaaaaaaaaaaaaaaaaaaaaaa), 1)
  expect_equal(out$metrics$dataset, c("aaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbb"))
})

test_that("dg_download_many() flattens a ZIP dataset into several tables", {
  local_mocked_bindings(
    dg_pull_dataset = function(id, remove_na = FALSE) {
      list(
        "data.csv" = data.frame(a = 1:2),
        "notes.tsv" = data.frame(c = 1)
      )
    },
    summarise_datasets = function(datasets) tibble::tibble(dataset = names(datasets))
  )

  out <- dg_download_many("aaaaaaaaaaaaaaaaaaaaaaaa")

  # The downloaded tables are flattened to a flat named list (one per parsed
  # file), with matching metrics rows.
  expect_named(out$datasets, c("aaaaaaaaaaaaaaaaaaaaaaaa / data.csv",
                               "aaaaaaaaaaaaaaaaaaaaaaaa / notes.tsv"))
  expect_equal(nrow(out$datasets[[1]]), 2)
  expect_equal(out$metrics$dataset, names(out$datasets))
})

test_that("dg_download_many() forwards remove_na to dg_pull_dataset()", {
  seen <- c()
  local_mocked_bindings(
    dg_pull_dataset = function(id, remove_na = FALSE) {
      seen <<- c(seen, remove_na)
      data.frame(x = 1)
    },
    summarise_datasets = function(datasets) tibble::tibble(dataset = "A")
  )

  dg_download_many("aaaaaaaaaaaaaaaaaaaaaaaa", remove_na = TRUE)

  expect_true(seen[[1]])
})
