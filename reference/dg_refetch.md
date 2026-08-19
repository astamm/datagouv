# Re-fetch a single parsed table by its stable identifier

Downloads again the exact table addressed by a composed table id, stored
as an `id` attribute on the tables returned by
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)
and readable with
[`dg_table_id()`](https://astamm.github.io/datagouv/reference/dg_table_id.md).
The id is built from the platform's own stable identifiers (dataset id +
resource id, plus the file name inside a ZIP), so this reproducibly
returns the same table, independent of the human-readable list keys.

## Usage

``` r
dg_refetch(x, remove_na = FALSE)
```

## Arguments

- x:

  Either a table returned by
  [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)
  or `dg_refetch()` (its `id` attribute is read automatically) or a
  composed table id string of the form `<dataset_id>::<resource_id>` or
  `<dataset_id>::<resource_id>::<file>`.

- remove_na:

  Whether to drop rows containing any `NA` value (passed to
  `format_tibble()`). Defaults to `FALSE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
— the single re-fetched table (the id addresses one table, not a
multi-file ZIP as a whole). The table's id is attached as an `id`
attribute.

## Examples

``` r
if (FALSE) { # interactive()
tbl <- dg_pull_dataset("6397c0ff56d3963118a18345")
again <- dg_refetch(tbl)
}
```
