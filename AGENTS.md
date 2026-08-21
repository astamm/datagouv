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
| Summarise table contents | [`dg_summary()`](https://astamm.github.io/datagouv/reference/dg_summary.md), [`dg_summarise()`](https://astamm.github.io/datagouv/reference/dg_summarise.md) |
| Re-fetch a table reproducibly | [`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md) |

The design rationale and full history live in `DESIGN-discovery.md`
(top-level, ignored by R CMD build). The README and the vignette
`vignettes/datagouv.qmd` document usage for end users.

## Public API (7 exports)

- `dg_list_datasets(q = NULL, n = 1000, format = catalog_formats(), schema_only = FALSE)`
  -\> tibble with columns
  `title, id, description, slug, n_resources, formats, has_table, has_schema`.
  `q` is server-side full-text search; `n = Inf` fetches the whole
  catalog; `format` narrows to datasets holding a resource in one of the
  given formats (queried server-side one format at a time, then unioned
  and de-duplicated by id — the API honors only a single `format` value
  per query, so passing several is *not* an OR on the server);
  `schema_only = TRUE` keeps only datasets declaring a schema.
  `fetch_all_datasets()`/`fetch_datasets_page()` page at
  `page_size = 1000` by default (up from 100).
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
- `dg_summary(x, name = NULL)` -\> one-row metrics tibble:
  `dataset, size_kb, n_vars, n_numeric, n_non_numeric, n_rows, prop_missing`.
- `dg_summarise(datasets = NULL, n = 100)` -\> metrics over many tables.
  Accepts a named list of tibbles, a nested list (ZIP), a
  [`dg_list_datasets()`](https://astamm.github.io/datagouv/reference/dg_list_datasets.md)
  tibble, a character vector of ids, or `NULL` (first `n` of the
  catalog).

Note: `format_tibble()` is **not exported** (used internally and in
tests).

## Source layout

- `R/utils.R` — internal HTTP + parsing helpers: `req_data_gouv()`
  (user-agent, 30s timeout, retry on 429/5xx), `fetch_datasets_page`,
  `fetch_all_datasets`, `fetch_dataset`, `find_dataset`,
  `supported_formats()`, `catalog_formats()`, `resource_has_schema()`,
  `read_first_parseable_resource`, `prefer_lightest_file`,
  `guess_delimiter`, `read_json_file`, `parse_resource_file`,
  `read_zip_resource`, `read_one_zip_file`, `read_resource`,
  `download_resource`, `format_tibble`, `compose_table_id` /
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
- `R/dg-summary.R` —
  [`dg_summary()`](https://astamm.github.io/datagouv/reference/dg_summary.md)
  (single-table metrics).
- `R/dg-summarise.R` —
  [`dg_summarise()`](https://astamm.github.io/datagouv/reference/dg_summarise.md) +
  internal `flatten_tables`.
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
as a table. The API honors a single `format` value per query, so
`fetch_all_datasets()` queries each requested format separately and
unions/deduplicates by dataset id. - `supported_formats()` =
`c("zip", "csv", "csv.gz", "xls", "xlsx", "parquet", "tsv", "txt", "json")`
— everything a direct pull can parse. JSON/TSV/TXT are intentionally NOT
in the catalog (not guaranteed tabular) but remain parseable when
addressed directly.

**Lightest-file selection.** When a dataset offers the *same table* in
several formats (same base file name, different extension),
`read_first_parseable_resource()` reduces the candidates to the one with
the smallest advertised `filesize` (`prefer_lightest_file()`), so
[`dg_pull_dataset()`](https://astamm.github.io/datagouv/reference/dg_pull_dataset.md)/[`dg_refetch()`](https://astamm.github.io/datagouv/reference/dg_refetch.md)
download the lighter copy. Resources with distinct names keep their
declared order.

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
[`dg_summary()`](https://astamm.github.io/datagouv/reference/dg_summary.md)/[`dg_summarise()`](https://astamm.github.io/datagouv/reference/dg_summarise.md)
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
  not `dg_list_datasets.R`).
- All HTTP goes through `req_data_gouv()` + `http_perform()` (consistent
  user-agent, timeouts, retries).
- Tests: testthat edition 3, files in `tests/testthat/` (`test-dg-*.R`,
  `test-dg-summary.R`, `test-dg-summarise.R`, `test-utils.R`); mocks in
  `helper-data.R` (`mock_dataset`, `mock_resource`, `mock_csv_data`);
  snapshots under `_snaps/`. Run `devtools::test()`.
- **Examples in roxygen**: use `@examples` for network-free code (e.g.
  `dg_summary`, and the in-memory branch of `dg_summarise`) and
  `@examplesIf interactive()` for anything that hits the live API (a
  live call in `@examples` breaks `R CMD check`).

## Documentation / build

- README is Quarto: edit `README.qmd`, regenerate `README.md` via
  `quarto::quarto_render("README.qmd", "gfm")`. Do not hand-edit
  README.md.
- One Quarto vignette: `vignettes/datagouv.qmd`. It uses a knitr chunk
  hook so live-API chunks (marked `#| live: true`) run only when the
  `DATAGOUV_LIVE=1` env var is set (the pkgdown workflow sets it so the
  site shows real output). They are skipped otherwise — including during
  `R CMD build`/`R CMD check`, which render the vignette in a subprocess
  where `_R_CHECK_PACKAGE_NAME_` is NOT set and so cannot be used to
  gate live code. DESCRIPTION needs `VignetteBuilder: quarto`,
  `Config/Quarto/version`, and `knitr`/`quarto` in Suggests.
- `_pkgdown.yml` lists all 7 exports in the reference sections and
  registers the vignette under `articles`.
- Regenerate docs with `devtools::document()`; verify with
  `devtools::test()` and `devtools::check()`.

## R-hub CI troubleshooting (as of 2026-08-21)

The R-hub GitHub Actions workflow (`.github/workflows/rhub.yaml`) has
been fighting three distinct, mostly *upstream* R-devel container
problems. All are transient platform artifacts — none reflect a defect
in the package (local `R CMD build` + test suite, 0 errors, are green):

- **Stale R-devel snapshots break rlang from source.** Containers `c23`,
  `clang16`–`clang20`, `gcc13`–`gcc15` carry R-devel r89629/r89623
  (2026-03), which predate the `R_envSymbols` header (added r89633) by
  hours, so current rlang (\>=1.1.7, e.g. 1.3.0) fails to compile from
  source (`use of undeclared identifier 'R_envSymbols'`). These are
  excluded from the Linux matrix until r-hub rebuilds them past r89633.
- **clang21** (healthy newer snapshot r90185) breaks because the r-hub
  CRAN *binary* `bit64` links against `libclang_rt.ubsan_standalone`,
  missing at load time -\> readr-based parsing fails in tests +
  vignette. Root fix is to make the “Build dependencies from source”
  step (sets `options(pkg.platforms = "source")` + `R_PROFILE`) actually
  force source builds — it did NOT prevent that binary pull. **Open
  thread:** investigate why the source-only flag isn’t honored there
  (c23 and the excluded rlang builds also work through this path, so the
  flag’s reach is inconsistent).
- **windows (R-devel) vignette:** freshly-installed package passed
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) yet did
  not expose `dg_summarise` (while `dg_summary` was callable) in the
  build subprocess. R-devel-Windows-specific; not reproducible on macOS.

### The `dg` opts_hook (vignette) — why and how

`vignettes/datagouv.qmd` sets
[`knitr::opts_hooks`](https://rdrr.io/pkg/knitr/man/opts_hooks.html) for
`live` (DATAGOUV_LIVE=1) and `dg`. The `dg` hook gates the two
network-free in-memory chunks so a bad environment degrades to a skip
instead of failing `R CMD build`. Each chunk sets
`#| dg: <function name>` (e.g. `dg: dg_summarise`); the hook evaluates
the chunk only when `"package:datagouv" %in% search()` **and**
`exists(<fn>, inherits = TRUE)`. A bare
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) check proved
too weak (it passed on Windows yet the export was missing), hence the
per-function search-path test.

**Assessment: does the gate mask a real partial-install bug?** No
package-side mechanism can drop a single export (namespaces load
atomically; `dg-summarise.R` is the only source file with no non-ASCII,
no load-time side effects; all 7 exports resolve to callable functions
locally). The anomaly fits the known run of R-hub install/hash
artifacts. Caveat: run 32387247290 aborted at the vignette before the
Windows *test suite* ran, so there is no Windows test signal confirming
`dg_summarise` — if a future Windows run shows the tests failing on
`dg_summarise` specifically, that would point to a real
platform-specific bug the gate would hide. The gate checks binding
*presence* (`exists`), not that the call succeeds; it is a
vignette-display guard, not a package-correctness check (the test suite
is the right place for that).
