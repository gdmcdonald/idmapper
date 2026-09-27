# Restrict a dataset to rows matching an existing identity graph

Keeps only the rows of `df` that have at least one marked identifier
already present in an entity type's identity graph - without adding any
new identifiers or edges to that graph. Useful for datasets you want to
enrich/cross-check against known identities (e.g. an LDAP extract) but
not treat as a source of new identity links.

## Usage

``` r
filter_by_existing_identities(df, env_name = "person", verbose = FALSE)
```

## Arguments

- df:

  A data frame with one or more columns marked via
  [`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md).

- env_name:

  Entity type name to check against (default `"person"`).

- verbose:

  If `TRUE`, print how many rows were kept.

## Value

`df`, filtered to rows with at least one matching identifier for
`env_name`. If that entity type's graph is empty, or `df` has no marked
columns for it, returns a zero-row slice of `df`.
