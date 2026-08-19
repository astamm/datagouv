# Documented schema of a parsed table's columns

Returns the declared data schema of a table's columns: the per-variable
`fields` recorded by the dataset producer. Because data.gouv attaches a
schema only as a *pointer* (`schema$name` / `schema$url`), this resolves
that pointer against [schema.data.gouv.fr](https://schema.data.gouv.fr)
and returns the human-readable column documentation (`name`, `title`,
`description`, `type`) that the schema carries — the information needed
to judge whether a variable really means what a statistical exploration
assumes.

## Usage

``` r
dg_schema(id)
```

## Arguments

- id:

  A composed table id of the form `<dataset_id>::<resource_id>` or
  `<dataset_id>::<resource_id>::<file>`, as stored in the `.id` column
  of the tables returned by
  [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per column and the columns `name`, `title`, `description`,
`type` and `example` (where the schema provides them; absent entries are
`NA`), or `NULL` (with a message) if the resource has no declared
schema. The schema's own `title` and `name` are attached as the
attributes `schema_title` and `schema_name`.

## Details

This is a *supplement* to
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md):
the table itself comes from the main API; the schema is read from the
producer's declared data specification. Only resources that carry a
schema pointer have documentation; resources without one return `NULL`
with a message. Use
[`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
(column `has_schema`, or the `schema_only` argument) to target
schema-documented tables in the first place.

## Examples

``` r
if (FALSE) { # interactive()
tables <- dg_pull_dataset("62c5961ff0013fb71d7278e3")
dg_schema(tables[[1]]$.id[1])
}
```
