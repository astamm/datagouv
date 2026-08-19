# AGENTS.md

Guidance for AI agents (and returning humans) working on the `datagouv`
R package. Establishes the package’s intent, architecture and
conventions so future sessions can pick up context quickly.

## Purpose

`datagouv` is an R client for the public API of data.gouv.fr, the French
government’s open-data platform. Its **primary intent** (the reframed
goal that drives the design):

> Let students/data scientists find a dataset matching their interests,
> judge whether it is usable, fetch it, and re-fetch the exact same
> table reproducibly.

Four workflow steps, each mapping to exported functions:

| Step | Function |
|----|----|
| Find / search the catalog | [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md) |
| Judge documented columns | [`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md) |
| Download tabular resources | [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md) |
| Summarise table contents | [`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md), [`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md) |
| Re-fetch a table reproducibly | [`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md) |
| Download several at once | [`dg_download_many()`](https://astamm.github.io/datagouv/reference/dg_download_many.md) |

The design rationale and full history live in `DESIGN-discovery.md`
(top-level, ignored by R CMD build). The README and the vignette
`vignettes/datagouv.qmd` document usage for end users.

## Public API (8 exports)

- `dg_list_datasets(q = NULL, n = 1000, schema_only = FALSE)` -\> tibble
  with columns
  `title, id, description, slug, n_resources, formats, has_table, has_schema`.
  `q` is server-side full-text search; `n = Inf` fetches the whole
  catalog; `schema_only = TRUE` keeps only datasets declaring a schema.
- `dg_pull_dataset(id, all_files = FALSE, remove_na = FALSE)` -\> a
  **single tibble** (the first parseable resource; a ZIP yields its
  first parseable file). `all_files = TRUE` returns a named list (one
  element per ZIP file). Every table carries its composed id as an `id`
  **attribute** (not a column), set by `table_attr()` and read by
  [`dg_table_id()`](https://astamm.github.io/datagouv/reference/dg_table_id.md)/`table_id_from_attr()`.
- `dg_refetch(x, remove_na = FALSE)` -\> a **single tibble** re-fetched
  from a composed id; `x` may be a table (its `id` attribute is read) or
  a bare id string.
- `dg_schema(x)` -\> tibble (`name, title, description, type, example`)
  of a table’s documented columns, with `schema_title`/`schema_name`
  attributes; `NULL` + message when the resource declares no schema;
  errors if the resource is not found. `x` may be a table or a composed
  id string.
- `dg_table_id(x)` -\> the composed id string of a pulled/re-fetched
  table, or `NULL` for an ordinary data frame.
- `get_summary(x, name = NULL)` -\> one-row metrics tibble:
  `dataset, size_kb, n_vars, n_numeric, n_non_numeric, n_rows, prop_missing`.
- `summarise_datasets(datasets = NULL, n = 100)` -\> metrics over many
  tables. Accepts a named list of tibbles, a nested list (ZIP), a
  [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
  tibble, a character vector of ids, or `NULL` (first `n` of the
  catalog).
- `dg_download_many(ids, remove_na = FALSE)` -\>
  `list(datasets, metrics)`.

Note: `format_tibble()` is **not exported** (used internally and in
tests).

## Source layout

- `R/utils.R` — internal HTTP + parsing helpers: `req_data_gouv()`
  (user-agent, 30s timeout, retry on 429/5xx), `fetch_datasets_page`,
  `fetch_all_datasets`, `fetch_dataset`, `find_dataset`,
  `supported_formats()`, `catalog_formats()`, `resource_has_schema()`,
  `read_first_parseable_resource`, `guess_delimiter`, `read_json_file`,
  `parse_resource_file`, `read_zip_resource`, `read_one_zip_file`,
  `read_resource`, `download_resource`, `compose_table_id` /
  `parse_table_id`, `table_attr` / `table_id_from_attr` /
  `resolve_table_id`, `%||%`, `uniquify_names`, `is_dataset_id`.
- `R/dg-list-datasets.R` —
  [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md).
- `R/dg-pull-dataset.R` —
  [`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md).
- `R/dg-table-id.R` —
  [`dg_table_id()`](https://astamm.github.io/datagouv/reference/dg_table_id.md).
- `R/dg-refetch.R` —
  [`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md) +
  `parse_table_id` validation.
- `R/dg-schema.R` —
  [`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md) +
  `field_attr()` + `resolve_schema_url()`.
- `R/core-functions.R` — `get_summary`, `summarise_datasets`,
  `flatten_tables`, `dg_download_many` (and internal `format_tibble`).
- `R/datagouv-package.R` — package-level `.Rd`.

## Core design concepts

**Composed table id.** Each parsed table’s address is
`<dataset_id>::<resource_id>` (single file) or
`<dataset_id>::<resource_id>::<file>` (a file inside a ZIP).
`dataset_id` is a 24-hex ObjectId, `resource_id` a UUID, `<file>` a base
name; `::` never appears in those fields. Built from the platform’s own
identifiers, so it is stable and re-fetchable, unlike human-readable
titles. Stored as the `id` **attribute** of each table by
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)/[`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md)
(not a column);
[`dg_table_id()`](https://astamm.github.io/datagouv/reference/dg_table_id.md)
and
[`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md)/[`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md)
consume it. Set *after* parsing so low-level readers stay untouched.

**Format handling — two lists, deliberately different.** -
`catalog_formats()` = `c("csv", "csv.gz", "xls", "xlsx", "parquet")` —
the official tabular formats data.gouv.fr indexes. The **discovery
catalog**
([`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md))
is restricted to these so every listed dataset is in principle openable
as a table. - `supported_formats()` =
`c("zip", "csv", "csv.gz", "xls", "xlsx", "parquet", "tsv", "txt", "json")`
— everything a direct pull can parse. JSON/TSV/TXT are intentionally NOT
in the catalog (not guaranteed tabular) but remain parseable when
addressed directly.

**Schema resolution.** data.gouv attaches a schema only as a *pointer*
(`resource$schema = {name, url, version}`).
[`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md)
resolves the pointer — the `url` directly, or the `name` via
`resolve_schema_url()` against `schema.data.gouv.fr` — to a Table Schema
document and returns its `fields`. Real per-column descriptions live
here, not in the main API (coverage surveyed: ~36.9% of datasets
tabular, ~5.1% carry a schema pointer, ~4.5% both). Schemas are
inconsistent: some omit per-field `title` or `description`;
`field_attr()` coerces absent/empty values to `NA` (jsonlite turns an
empty `description=NULL` into [`{}`](https://rdrr.io/r/base/Paren.html),
i.e. a zero-length list, not `NULL` — handle both).

**Metrics and the id attribute.** Because the composed id is a table
*attribute*, not a column,
[`get_summary()`](https://astamm.github.io/datagouv/reference/get_summary.md)/[`summarise_datasets()`](https://astamm.github.io/datagouv/reference/summarise_datasets.md)
need no special exclusion — it never inflates
`n_vars`/`n_numeric`/`n_non_numeric`/ `prop_missing`.

## Architecture / division of labour

Main API (`www.data.gouv.fr/api/1`) is the **backbone**: catalog keyword
search, discovery metadata, and raw file downloads. The tabular API
(`tabular-api.data.gouv.fr`) is a **supplement** but is NOT used by the
current implementation:
[`dg_schema()`](https://astamm.github.io/datagouv/reference/dg_schema.md)
pulls documented fields from `schema.data.gouv.fr` instead of the
tabular API `/profile/` endpoint that an early design sketch mentioned.
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)
downloads raw files itself to preserve full format/coverage (unindexed
resources 404 on the tabular service).

## Conventions & gotchas

- Source files use **hyphens**, not underscores (`dg-list-datasets.R`,
  not `dg_list_datasets.R`). `wrapper_datasets()` was renamed to
  [`dg_download_many()`](https://astamm.github.io/datagouv/reference/dg_download_many.md);
  do not reintroduce the old name.
- All HTTP goes through `req_data_gouv()` + `http_perform()` (consistent
  user-agent, timeouts, retries).
- Tests: testthat edition 3, files in `tests/testthat/` (`test-dg-*.R`,
  `test-get-summary.R`, `test-summarise-datasets.R`, `test-utils.R`,
  `test-dg-download-many.R`); mocks in `helper-data.R` (`mock_dataset`,
  `mock_resource`, `mock_csv_data`); snapshots under `_snaps/`. Run
  `devtools::test()` — currently 210 passing.
- **Examples in roxygen**: use `@examples` for network-free code (e.g.
  `get_summary`, and the in-memory branch of `summarise_datasets`) and
  `@examplesIf interactive()` for anything that hits the live API (a
  live call in `@examples` breaks `R CMD check`).

## Documentation / build

- README is Quarto: edit `README.qmd`, regenerate `README.md` via
  `quarto::quarto_render("README.qmd", "gfm")`. Do not hand-edit
  README.md.
- One Quarto vignette: `vignettes/datagouv.qmd`. It uses a knitr chunk
  hook so live-API chunks (marked `#| live: true`) run only
  interactively and are skipped during `R CMD check`. DESCRIPTION needs
  `VignetteBuilder: quarto`, `Config/Quarto/version`, and
  `knitr`/`quarto` in Suggests.
- `_pkgdown.yml` lists all 7 exports in the reference sections and
  registers the vignette under `articles`.
- Regenerate docs with `devtools::document()`; verify with
  `devtools::test()` and `devtools::check()`.
