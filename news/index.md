# Changelog

## datagouv 0.0.0.9000

- Initial development version.
- [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
  lists all datasets available on data.gouv.fr and returns a tibble with
  `title`, `id`, `description` and `slug`.
- `format_tibble()` converts a data frame to a tibble and can drop rows
  containing missing values.
- [`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md)
  computes key metrics (weight, number of variables, number of rows,
  missing-value proportion) for a dataset.
- [`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
  computes summary metrics over a collection of datasets, disambiguating
  duplicate titles in the output by appending each dataset’s id.
- [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)
  downloads a dataset by its stable, unique `id` (and, as a fallback, by
  exact title) and parses it.
- `read_resource()` auto-detects the delimiter of CSV/TXT resources
  (comma, semicolon, tab, pipe, …) and dispatches to the matching
  `readr` reader (`read_csv()`, `read_csv2()` for European files,
  `read_tsv()`, `read_delim()`), and adds support for JSON resources
  (array or newline-delimited) via `jsonlite`.
- `wrapper_datasets()` downloads several datasets by `id` and returns
  both the raw tables and the summary metrics.
- [`dg_download_many()`](https://astamm.github.io/datagouv/reference/dg_download_many.md)
  replaces `wrapper_datasets()` (renamed); `wrapper_datasets()` is no
  longer available.
- [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)
  now tags every returned table with a stable, unique `id` column of the
  form `<dataset>::<resource>` (or `<dataset>::<resource>::<file>` for a
  file inside a ZIP), built from the platform’s own identifiers.
- [`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md)
  re-fetches a single table from its composed `id`, reproducibly
  returning the same table across calls.
- [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
  now also reports `n_resources` (file count), `formats` (distinct file
  formats) and `has_table` (whether a resource can be parsed to a table)
  for each dataset.
- [`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
  accepts a tibble returned by
  [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
  (identified by its `id` column) and summarises the matching datasets.
- [`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md)
  returns the documented column metadata (`name`, `title`,
  `description`, `type`, `example`) declared in the dataset’s data
  schema on schema.data.gouv.fr, resolved from a resource’s schema
  pointer, or `NULL` (with a message) when the resource carries no
  schema.
- [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
  now reports `has_schema` (whether at least one resource carries a
  pointer to a declared data schema) and gains a `schema_only` argument
  to keep only schema-documented datasets.
- The discovery catalog
  ([`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md))
  is now restricted to data.gouv’s official tabular formats (`csv`,
  `csv.gz`, `xls`, `xlsx`, `parquet`) so every listed dataset is in
  principle openable as a table.
- `supported_formats()` now also parses `xls` (legacy Excel) and
  `parquet` resources; `nanoparquet` is a new hard dependency.
- [`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md)
  and
  [`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
  exclude the `.id` column from variable and missing-value metrics.
- [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)
  now skips a dataset resource whose declared format cannot actually be
  parsed into a table (e.g. a `json` resource serving an API metadata
  document) and falls back to the next tabular resource, instead of
  erroring on the first candidate.
- `read_json_file()` now reports a clear, actionable error when a
  top-level JSON object is not tabular data (e.g. an API metadata
  document with variable-length fields) rather than a cryptic
  tibble-size error.
