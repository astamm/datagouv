# datagouv

## Overview

`datagouv` provides a small client for the public API of
[data.gouv.fr](https://www.data.gouv.fr), the French government’s open
data platform. It lets you list the datasets published on the platform,
download their tabular resources and compute summary metrics (file
weight, number of columns, missing-value rates, …). Requests are built
on top of the [`httr2`](https://httr2.r-lib.org) package.

The approach mirrors what several US cities propose (e.g.
[`nycOpenData`](https://github.com/ropensci/nycOpenData) for New York),
but tailored to the data.gouv.fr API.

## Installation

``` r

# From GitHub once published
# remotes::install_github("stamm-a/datagouv")
```

## Usage

List the datasets available on the platform:

``` r

library(datagouv)

datasets <- list_datasets()
head(datasets)
```

Download a dataset by its name:

``` r

df <- get_dataset("Example dataset title")
```

Compute summary metrics on a single dataset or over several:

``` r

# single dataset
get_summary(iris, name = "iris")

# several datasets at once (defaults to the first 100 of list_datasets())
summarise_datasets(datasets = list(iris = iris, mtcars = mtcars))
```

Download several datasets and get both the raw tables and the metrics:

``` r

out <- wrapper_datasets(c("iris", "mtcars"))
out$datasets  # named list of tibbles
out$metrics   # summary tibble
```

## Supported formats

[`get_dataset()`](https://astamm.github.io/datagouv/reference/get_dataset.md)
downloads the first tabular resource of a dataset among CSV, CSV.GZ,
TSV, TXT and XLSX.

## License

MIT © A. Stamm
