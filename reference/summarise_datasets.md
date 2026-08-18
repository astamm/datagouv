# Summarise several datasets

Applies
[`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md)
to a collection of datasets and combines the resulting metrics into a
single tibble. If `datasets` is `NULL`, the first `n` datasets returned
by
[`list_datasets()`](https://astamm.github.io/datagouv/reference/list_datasets.md)
are downloaded and summarised.

## Usage

``` r
summarise_datasets(datasets = NULL, n = 100)
```

## Arguments

- datasets:

  Either a named list of tibbles, a character vector of dataset names to
  download, or `NULL` (the default) to use the first `n` datasets from
  [`list_datasets()`](https://astamm.github.io/datagouv/reference/list_datasets.md).

- n:

  Number of datasets to summarise when `datasets` is `NULL`. Defaults to
  `100`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per dataset and the columns described in
[`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md).

## Examples

``` r
if (FALSE) { # interactive()
summarise_datasets(datasets = list(iris = iris), n = 2)
}
```
