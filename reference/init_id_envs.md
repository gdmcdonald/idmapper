# Initialise identity graph environments

Creates one empty identity graph per named entity type (for example
`"person"`, `"project"`). Must be called before
[`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md)
/
[`add_to_identity_graph()`](https://gdmcdonald.github.io/idmapper/reference/add_to_identity_graph.md)
for a given entity type, and is safe to call again later to reset a type
back to an empty graph.

## Usage

``` r
init_id_envs(
  names = c("person", "project", "organisation"),
  suffix = "_env",
  envir = NULL,
  init_graph = TRUE
)
```

## Arguments

- names:

  Character vector of entity type names to initialise.

- suffix:

  Kept only for backwards compatibility with the original `id_map.R`
  script's argument list; no longer used, since state is now stored
  internally rather than as `<name>_env` variables in a target
  environment.

- envir:

  Kept only for backwards compatibility; ignored. State is always stored
  in an internal package environment now, never in `envir`.

- init_graph:

  If `TRUE` (the default), initialise each entity type with an empty,
  undirected graph
  ([`igraph::make_empty_graph()`](https://r.igraph.org/reference/make_empty_graph.html)).

## Value

Invisibly, `NULL`. Called for its side effect of creating (or resetting)
package-internal state for each entity type in `names`.

## Examples

``` r
init_id_envs(c("person", "project"))
```
