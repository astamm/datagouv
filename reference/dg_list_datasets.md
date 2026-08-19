# List datasets available on data.gouv.fr

Collects the names (titles) of datasets published on the data.gouv.fr
platform. By default it returns the first `n` datasets; use `q` to
search titles and descriptions server-side instead of enumerating the
whole catalog.

## Usage

``` r
dg_list_datasets(
  q = NULL,
  n = 1000,
  format = catalog_formats(),
  schema_only = FALSE
)
```

## Arguments

- q:

  Optional full-text search query. When given, only datasets matching
  `q` are returned (the API performs the search). Defaults to `NULL`,
  meaning no filtering.

- n:

  Maximum number of datasets to return. Defaults to `1000`. Set to `Inf`
  to retrieve everything (the whole catalog).

- format:

  Optional character vector of resource formats to keep. When given,
  only datasets that have at least one resource in one of these formats
  are returned; each requested format is queried server-side and the
  results are combined. Defaults to the full set of officially tabular
  formats (`csv`, `csv.gz`, `xls`, `xlsx`, `parquet`).

- schema_only:

  Whether to keep only datasets that declare a data schema (see
  `has_schema`). Defaults to `FALSE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per matching dataset and the columns `title`, `id`,
`description`, `slug`, `n_resources`, `formats`, `has_table` and
`has_schema`. The `id` column holds the stable, unique dataset
identifier used to address a dataset with
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md).
`n_resources` is the number of files/resources in the dataset, `formats`
lists the distinct file formats found among them, `has_table` indicates
whether at least one resource is in a format that can be parsed into a
table by this package, and `has_schema` indicates whether at least one
resource carries a pointer to a declared data schema (whose per-variable
documentation is exposed by
[`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md)).

## Details

Fetching *every* dataset on the platform means paging through tens of
thousands of records in hundreds of HTTP requests and is both slow and
fragile, so the default is deliberately bounded. Set `n = Inf` to return
all titles regardless of count.

## Examples

``` r
if (FALSE) { # interactive()
datasets <- dg_list_datasets(n = 20)
head(datasets)

# Search server-side instead of downloading the whole catalog.
cycle <- dg_list_datasets(q = "vélo", n = 10)

# Only datasets that carry at least one parquet resource (a more compact
# format than CSV, so a later download is lighter).
parquet <- dg_list_datasets(format = "parquet", n = 10)

# Only datasets with a declared schema (documented variables).
documented <- dg_list_datasets(schema_only = TRUE, n = 10)
}
```
