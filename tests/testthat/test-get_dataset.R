test_that("get_dataset() downloads and formats a dataset", {
  local_mocked_bindings(
    find_dataset = function(name) mock_dataset(title = name),
    pick_resource = function(dataset) mock_resource("csv"),
    read_resource = function(resource) mock_csv_data()
  )

  out <- get_dataset("Example dataset")

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 3)
  expect_named(out, c("a", "b"))
})

test_that("get_dataset() forwards remove_na to format_tibble()", {
  local_mocked_bindings(
    find_dataset = function(name) mock_dataset(title = name),
    pick_resource = function(dataset) mock_resource("csv"),
    read_resource = function(resource) mock_csv_data()
  )

  out <- get_dataset("Example dataset", remove_na = TRUE)

  expect_equal(nrow(out), 2)
})
