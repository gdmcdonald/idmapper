# Add a marked dataset to its identity graph(s)

Reads the `graph`/`id_type` attributes set by
[`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md)
on `df`'s columns, and for each entity type found:

1.  treats every distinct `(id_type, id_value)` pair across all marked
    columns as a node (creating any that don't already exist);

2.  for any row where two or more of those nodes co-occur, adds an edge
    between every pair of them, on the assumption that identifiers
    appearing together on the same row belong to the same real-world
    entity.

Repeated calls across multiple datasets accumulate into the same graph,
which is what lets
[`generate_master_identity_table()`](https://gdmcdonald.github.io/idmapper/reference/generate_master_identity_table.md)
later resolve a single master identity across sources that never share a
common key directly, but are transitively linked through others that do.

## Usage

``` r
add_to_identity_graph(df, env_name = NULL, debug = FALSE)
```

## Arguments

- df:

  A data frame with one or more columns marked via
  [`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md).

- env_name:

  Optional character vector restricting processing to these entity types
  only (by default, every entity type found among `df`'s marked columns
  is processed).

- debug:

  If `TRUE`, print diagnostic information about the columns, nodes, and
  edges being processed.

## Value

Invisibly, `df` (unchanged), so this can be used at the end of a pipe
purely for its side effect of updating the relevant identity graph(s).
