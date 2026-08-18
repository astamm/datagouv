# Download a dataset from data.gouv.fr

Downloads the first tabular resource of a dataset and parses it into a
tibble with
[`format_tibble()`](https://astamm.github.io/datagouv/reference/format_tibble.md).
The dataset is identified by its `id`, which is the stable, unique
identifier returned in the `id` column of
[`list_datasets()`](https://astamm.github.io/datagouv/reference/list_datasets.md).
For backwards compatibility, an exact title is also accepted and is
resolved by searching the platform.

## Usage

``` r
get_dataset(id, remove_na = FALSE)
```

## Arguments

- id:

  The identifier of the dataset to download (or, as a fallback, its
  exact title). Identifiers are unique and stable, so they are the
  recommended way to address a dataset; titles can collide or change
  over time.

- remove_na:

  Whether to drop rows containing any `NA` value (passed to
  [`format_tibble()`](https://astamm.github.io/datagouv/reference/format_tibble.md)).
  Defaults to `FALSE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the parsed data.

## Examples

``` r
if (FALSE) { # interactive()
id <- "6397c0ff56d3963118a18345"
df <- get_dataset(id)
head(df)
}
```
