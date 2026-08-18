# datagouv 0.0.0.9000

- Initial development version.
- `list_datasets()` lists all datasets available on data.gouv.fr and returns a
  tibble with `title`, `id`, `description` and `slug`.
- `format_tibble()` converts a data frame to a tibble and can drop rows
  containing missing values.
- `get_summary()` computes key metrics (weight, number of variables, number of
  rows, missing-value proportion) for a dataset.
- `summarise_datasets()` computes summary metrics over a collection of
  datasets, disambiguating duplicate titles in the output by appending each
  dataset's id.
- `get_dataset()` downloads a dataset by its stable, unique `id` (and, as a
  fallback, by exact title) and parses it.
- `read_resource()` auto-detects the delimiter of CSV/TXT resources (comma,
  semicolon, tab, pipe, ...) and dispatches to the matching `readr` reader
  (`read_csv()`, `read_csv2()` for European files, `read_tsv()`,
  `read_delim()`), and adds support for JSON resources (array or
  newline-delimited) via `jsonlite`.
- `wrapper_datasets()` downloads several datasets by `id` and returns both the
  raw tables and the summary metrics.
