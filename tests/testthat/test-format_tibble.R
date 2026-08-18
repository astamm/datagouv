test_that("format_tibble() converts a data frame to a tibble", {
  df <- data.frame(a = 1:3, b = letters[1:3])

  out <- format_tibble(df)

  expect_s3_class(out, "tbl_df")
  expect_equal(out, tibble::as_tibble(df))
})

test_that("format_tibble() leaves NAs when remove_na is FALSE", {
  df <- data.frame(a = c(1, NA, 3), b = c("x", NA, "z"))

  out <- format_tibble(df, remove_na = FALSE)

  expect_equal(nrow(out), 3)
  expect_identical(is.na(out$a), c(FALSE, TRUE, FALSE))
  expect_identical(is.na(out$b), c(FALSE, TRUE, FALSE))
})

test_that("format_tibble() drops rows with NAs when remove_na is TRUE", {
  df <- data.frame(a = c(1, NA, 3), b = c("x", "y", NA))

  out <- format_tibble(df, remove_na = TRUE)

  expect_equal(nrow(out), 1)
  expect_equal(out$a, 1)
  expect_equal(out$b, "x")
})

test_that("format_tibble() accepts a tibble as input", {
  tb <- tibble::tibble(a = 1:3)

  out <- format_tibble(tb)

  expect_s3_class(out, "tbl_df")
  expect_equal(out, tb)
})

test_that("format_tibble() errors on non-data-frame input", {
  expect_snapshot(error = TRUE, format_tibble(1:10))
})
