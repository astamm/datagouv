test_that("dg_refetch() re-fetches a single-file table by its id", {
  did <- "aaaaaaaaaaaaaaaaaaaaaaaa"
  rid <- "99999999-9999-4999-8999-999999999999"
  id <- paste(did, rid, sep = "::")

  local_mocked_bindings(
    fetch_dataset = function(id) mock_dataset(title = id, id = id, resources =
      list(mock_resource("csv", id = rid))),
    read_resource = function(resource) mock_csv_data()
  )

  out <- dg_refetch(id)

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 3)
  expect_named(out, c("a", "b", ".id"))
  expect_equal(out$.id[1], id)
})

test_that("dg_refetch() re-fetches one file out of a ZIP", {
  did <- "aaaaaaaaaaaaaaaaaaaaaaaa"
  rid <- "99999999-9999-4999-8999-999999999999"
  id <- paste(did, rid, "notes.tsv", sep = "::")

  local_mocked_bindings(
    fetch_dataset = function(id) mock_dataset(title = id, id = id, resources =
      list(mock_resource("zip", id = rid))),
    read_one_zip_file = function(resource, name) data.frame(c = 1, d = "x")
  )

  out <- dg_refetch(id)

  expect_equal(nrow(out), 1)
  expect_named(out, c("c", "d", ".id"))
  expect_equal(out$.id[1], id)
})

test_that("dg_refetch() forwards remove_na to format_tibble()", {
  did <- "aaaaaaaaaaaaaaaaaaaaaaaa"
  rid <- "99999999-9999-4999-8999-999999999999"
  id <- paste(did, rid, sep = "::")

  local_mocked_bindings(
    fetch_dataset = function(id) mock_dataset(title = id, id = id, resources =
      list(mock_resource("csv", id = rid))),
    read_resource = function(resource) mock_csv_data()
  )

  out <- dg_refetch(id, remove_na = TRUE)

  # mock_csv_data() has one NA row; removing NA drops it.
  expect_equal(nrow(out), 2)
})

test_that("dg_refetch() errors on a malformed id", {
  expect_error(dg_refetch("not-a-table-id"), "Invalid table id")
})

test_that("dg_refetch() errors when the resource is not found", {
  did <- "aaaaaaaaaaaaaaaaaaaaaaaa"
  rid <- "99999999-9999-4999-8999-999999999999"

  local_mocked_bindings(
    fetch_dataset = function(id) mock_dataset(title = id, id = id, resources =
      list(mock_resource("csv", id = "other-resource")))
  )

  expect_error(
    dg_refetch(paste(did, rid, sep = "::")),
    "was not found on dataset"
  )
})
