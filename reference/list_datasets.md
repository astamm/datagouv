# List datasets available on data.gouv.fr

Collects the names (titles) of datasets published on the data.gouv.fr
platform. By default it returns the first `n` datasets; use `q` to
search titles and descriptions server-side instead of enumerating the
whole catalog.

## Usage

``` r
list_datasets(q = NULL, n = 1000)
```

## Arguments

- q:

  Optional full-text search query. When given, only datasets matching
  `q` are returned (the API performs the search). Defaults to `NULL`,
  meaning no filtering.

- n:

  Maximum number of datasets to return. Defaults to `1000`. Set to `Inf`
  to retrieve everything (the whole catalog).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per matching dataset and the columns `title`, `id`,
`description` and `slug`. The `id` column holds the stable, unique
dataset identifier used to address a dataset with
[`get_dataset()`](https://astamm.github.io/datagouv/reference/get_dataset.md).

## Details

Fetching *every* dataset on the platform means paging through tens of
thousands of records in hundreds of HTTP requests and is both slow and
fragile, so the default is deliberately bounded. Set `n = Inf` to return
all titles regardless of count.

## Examples

``` r
if (FALSE) { # interactive()
datasets <- list_datasets(n = 20)
head(datasets)

# Search server-side instead of downloading the whole catalog.
cycle <- list_datasets(q = "vélo", n = 10)
}
```
