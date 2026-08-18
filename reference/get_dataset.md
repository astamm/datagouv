# Download a dataset from data.gouv.fr

Searches the data.gouv.fr platform for a dataset whose title matches
`name`, downloads its first tabular resource and parses it into a tibble
with
[`format_tibble()`](https://astamm.github.io/datagouv/reference/format_tibble.md).

## Usage

``` r
get_dataset(name, remove_na = FALSE)
```

## Arguments

- name:

  The title of the dataset to download. Must match exactly one element
  of
  [`list_datasets()`](https://astamm.github.io/datagouv/reference/list_datasets.md).

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
name <- paste0(
  "Part des véhicules à faibles émissions dans le ",
  "renouvellement d'un parc (Nestlé France SAS) pour 2025"
)
df <- get_dataset(name)
head(df)
}
```
