# Collapse an identity graph into a master identity table

Finds the connected components of an entity type's identity graph (built
up via repeated
[`add_to_identity_graph()`](https://gdmcdonald.github.io/idmapper/reference/add_to_identity_graph.md)
calls) and collapses each component into a single master identity,
assigned an ID like `"PERSON-1"`, `"PERSON-2"`, .... The resulting table
has one row per master identity and one list-column per distinct
`id_type` seen (e.g. `email`, `unikey`), each holding every identifier
value that resolved to that identity.

## Usage

``` r
generate_master_identity_table(
  env_name = NULL,
  verbose = TRUE,
  id_prefix = NULL,
  store_in_env = TRUE
)
```

## Arguments

- env_name:

  Optional entity type name (e.g. `"person"`). If `NULL` (the default),
  a master table is generated for every entity type currently
  initialised via
  [`init_id_envs()`](https://gdmcdonald.github.io/idmapper/reference/init_id_envs.md),
  returned as a named list.

- verbose:

  If `TRUE` (the default), print progress messages.

- id_prefix:

  Prefix used for generated master IDs. Defaults to the upper-cased
  `env_name` followed by `"-"` (e.g. `"PERSON-"`).

- store_in_env:

  If `TRUE` (the default), also store the resulting table so
  [`get_master_table()`](https://gdmcdonald.github.io/idmapper/reference/get_master_table.md)
  can retrieve it later without regenerating it.

## Value

A tibble with one row per master identity: an ID column named
`"<env_name>_id"`, and one list-column per `id_type` found in the graph.
If `env_name` is `NULL`, a named list of such tibbles, one per entity
type.
