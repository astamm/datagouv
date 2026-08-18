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

A character vector containing the title of each matching dataset.

## Details

Fetching *every* dataset on the platform means paging through tens of
thousands of records in hundreds of HTTP requests and is both slow and
fragile, so the default is deliberately bounded. Set `n = Inf` to return
all titles regardless of count.

## Examples

``` r
if (FALSE) { # interactive()
names <- list_datasets(n = 20)
head(names)

# Search server-side instead of downloading the whole catalog.
cycle <- list_datasets(q = "vélo", n = 10)
}
```
