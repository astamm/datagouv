# datagouv 0.0.0.9000

- Initial development version.
- `list_datasets()` lists all datasets available on data.gouv.fr.
- `format_tibble()` converts a data frame to a tibble and can drop rows
  containing missing values.
- `get_summary()` computes key metrics (weight, number of variables, number of
  rows, missing-value proportion) for a dataset.
- `summarise_datasets()` computes summary metrics over a collection of
  datasets.
- `get_dataset()` downloads a dataset by name and parses it.
- `wrapper_datasets()` downloads several datasets and returns both the raw
  tables and the summary metrics.
