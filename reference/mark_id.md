# Mark identity columns for entity resolution

Tags one or more columns of `df` with attributes recording which entity
graph they belong to (e.g. `"person"`, `"project"`) and what kind of
identifier they represent (e.g. `"email"`, `"unikey"`). These attributes
are read later by
[`add_to_identity_graph()`](https://gdmcdonald.github.io/idmapper/reference/add_to_identity_graph.md)
(to build the identity graph) and
[`join_master_ids()`](https://gdmcdonald.github.io/idmapper/reference/join_master_ids.md)
(to attach a resolved master ID back onto `df`).

## Usage

``` r
mark_id(df, cols, graph = "person", type, exact = TRUE)
```

## Arguments

- df:

  A data frame.

- cols:

  One column, or several columns wrapped in
  [`c()`](https://rdrr.io/r/base/c.html), to mark. Uses tidy evaluation,
  so bare column names work directly:
  `mark_id(df, email, graph = "person", type = "email")` or
  `mark_id(df, c(email_from_hr, email_from_irma), graph = "person", type = "email")`.

- graph:

  Name of the entity graph this identifier belongs to. Should match a
  name previously passed to
  [`init_id_envs()`](https://gdmcdonald.github.io/idmapper/reference/init_id_envs.md).

- type:

  A label for this kind of identifier (e.g. `"email"`, `"unikey"`,
  `"staff_id"`). Two values are only ever considered candidates for the
  same identity if they share an `id_type`.

- exact:

  Currently unused; reserved for future fuzzy-matching support.

## Value

`df`, with `graph` and `id_type` attributes attached to the marked
column(s). No rows or columns are added, removed, or reordered.

## Examples

``` r
df <- data.frame(email = c("a@example.com", "b@example.com"))
df <- mark_id(df, email, graph = "person", type = "email")
attr(df$email, "graph")
#> [1] "person"
attr(df$email, "id_type")
#> [1] "email"
```
