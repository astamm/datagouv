# Download a dataset from data.gouv.fr

Downloads the first tabular resource of a dataset and parses it into
tibbles with `format_tibble()`. The dataset is identified by its `id`,
which is the stable, unique identifier returned in the `id` column of
[`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md).
For backwards compatibility, an exact title is also accepted and is
resolved by searching the platform.

## Usage

``` r
dg_pull_dataset(id, remove_na = FALSE)
```

## Arguments

- id:

  The identifier of the dataset to download (or, as a fallback, its
  exact title). Identifiers are unique and stable, so they are the
  recommended way to address a dataset; titles can collide or change
  over time.

- remove_na:

  Whether to drop rows containing any `NA` value (passed to
  `format_tibble()`). Defaults to `FALSE`.

## Value

A named list of
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the parsed data. A ZIP resource may contain several parseable
files, in which case the list has one element per file (named after it);
other formats yield a single element named after the resource. Each
table carries a trailing `.id` column holding its stable, unique address
(`<dataset_id>::<resource_id>(::<file>)`), re-fetchable with
[`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md).

## Examples

``` r
if (FALSE) { # interactive()
id <- "6397c0ff56d3963118a18345"
tables <- dg_pull_dataset(id)
head(tables[[1]])
}
```
