# Re-fetch a single parsed table by its stable identifier

Downloads again the exact table addressed by a composed table id as
stored in the `.id` column of the tables returned by
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md).
Because the id is built from the platform's own stable identifiers
(dataset id + resource id, plus the file name inside a ZIP), this
reproducibly returns the same table, independent of the human-readable
list keys.

## Usage

``` r
dg_refetch(id, remove_na = FALSE)
```

## Arguments

- id:

  A composed table id of the form `<dataset_id>::<resource_id>` or
  `<dataset_id>::<resource_id>::<file>`.

- remove_na:

  Whether to drop rows containing any `NA` value (passed to
  `format_tibble()`). Defaults to `FALSE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
— the single re-fetched table (the id addresses one table, not a
multi-file ZIP as a whole).

## Examples

``` r
if (FALSE) { # interactive()
tables <- dg_pull_dataset("6397c0ff56d3963118a18345")
again <- dg_refetch(tables[[1]]$.id[1])
}
```
