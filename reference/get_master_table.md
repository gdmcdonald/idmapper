# Retrieve a previously generated master identity table

Retrieve a previously generated master identity table

## Usage

``` r
get_master_table(env_name)
```

## Arguments

- env_name:

  Entity type name (e.g. `"person"`, `"project"`).

## Value

The tibble previously stored by
[`generate_master_identity_table()`](https://gdmcdonald.github.io/idmapper/reference/generate_master_identity_table.md)
for this entity type.
