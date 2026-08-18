# Download datasets and compute their metrics

Wrapper that downloads several datasets with
[`get_dataset()`](https://astamm.github.io/datagouv/reference/get_dataset.md),
computes their summary metrics with
[`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
and returns both the raw downloaded tibbles and the metrics in a single
list.

## Usage

``` r
wrapper_datasets(names, remove_na = FALSE)
```

## Arguments

- names:

  A character vector of dataset titles to download.

- remove_na:

  Whether to drop rows containing any `NA` value (passed to
  [`get_dataset()`](https://astamm.github.io/datagouv/reference/get_dataset.md)).
  Defaults to `FALSE`.

## Value

A list with two components:

- datasets:

  A named list of the downloaded tibbles.

- metrics:

  A tibble of summary metrics, as returned by
  [`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md).

## Examples

``` r
if (FALSE) { # interactive()
out <- wrapper_datasets(c("iris", "mtcars"))
names(out)
}
```
