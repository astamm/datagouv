# Package index

## Finding and downloading datasets

Find a dataset on data.gouv.fr, judge whether it is usable, and pull its
tabular resources into tidy tables.

- [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
  : List datasets available on data.gouv.fr
- [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)
  : Download a dataset from data.gouv.fr
- [`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md)
  : Re-fetch a single parsed table by its stable identifier
- [`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md)
  : Documented schema of a parsed table's columns
- [`dg_download_many()`](https://astamm.github.io/datagouv/reference/dg_download_many.md)
  : Download datasets and compute their metrics

## Summaries

Compute summary metrics (size, number of columns, missing-value rates,
…) on a single dataset or across several datasets.

- [`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md)
  : Compute summary metrics for a dataset
- [`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
  : Summarise several datasets
