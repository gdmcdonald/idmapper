# Attach resolved master IDs onto a dataset

For each entity type represented among `df`'s
[`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md)-marked
columns, looks up each row's identifier(s) against that entity type's
master identity table (see
[`generate_master_identity_table()`](https://gdmcdonald.github.io/idmapper/reference/generate_master_identity_table.md))
and attaches the resolved master ID as a new column (e.g. `person_UID`,
`project_UID`).

## Usage

``` r
join_master_ids(df, suffix = "_UID", verbose = FALSE)
```

## Arguments

- df:

  A data frame with one or more columns marked via
  [`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md).

- suffix:

  Suffix appended to each entity type's name to form its new ID column
  name (default `"_UID"`, e.g. `"person_UID"`).

- verbose:

  If `TRUE`, print progress messages.

## Value

`df` with one additional column per entity type found among its marked
columns (e.g. `person_UID`), each holding the row's resolved master ID,
or `NA` if none of that row's marked identifiers matched anything in the
master table.
