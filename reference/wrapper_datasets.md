# Download datasets and compute their metrics

Wrapper that downloads several datasets with
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md),
computes their summary metrics with
[`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
and returns both the raw downloaded tibbles and the metrics in a single
list.

## Usage

``` r
wrapper_datasets(ids, remove_na = FALSE)
```

## Arguments

- ids:

  A character vector of dataset identifiers to download (or exact
  titles, as a fallback). Identifiers are the stable, unique values in
  the `id` column of
  [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md).

- remove_na:

  Whether to drop rows containing any `NA` value (passed to
  [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)).
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
out <- wrapper_datasets("6397c0ff56d3963118a18345")
names(out)
}
```
