# Changelog

## datagouv 0.0.0.9000

- Initial development version.
- [`list_datasets()`](https://astamm.github.io/datagouv/reference/list_datasets.md)
  lists all datasets available on data.gouv.fr.
- [`format_tibble()`](https://astamm.github.io/datagouv/reference/format_tibble.md)
  converts a data frame to a tibble and can drop rows containing missing
  values.
- [`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md)
  computes key metrics (weight, number of variables, number of rows,
  missing-value proportion) for a dataset.
- [`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
  computes summary metrics over a collection of datasets.
- [`get_dataset()`](https://astamm.github.io/datagouv/reference/get_dataset.md)
  downloads a dataset by name and parses it.
- [`wrapper_datasets()`](https://astamm.github.io/datagouv/reference/wrapper_datasets.md)
  downloads several datasets and returns both the raw tables and the
  summary metrics.
