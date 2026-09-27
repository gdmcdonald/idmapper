# idmapper

📖 **[Documentation site](https://gdmcdonald.github.io/idmapper/)**

Entity resolution across multiple, separately maintained data sources -
tag identifier columns, link records that share an identifier, and
collapse everything into a single master ID per real-world entity
(e.g. person, project).

## Installation

``` r

remotes::install_github("gdmcdonald/idmapper")
```

## Usage

See
[`vignette("idmapper")`](https://gdmcdonald.github.io/idmapper/articles/idmapper.md)
for a worked example (synthetic data) showing why this is worth the
extra machinery over a plain `left_join()` - specifically, resolving two
records that share no identifier directly but are linked transitively
through a third dataset.

![Diagram: three dataset panels (race_results, fitness_app_leaderboard,
club_roster) with identifier nodes; solid lines link identifiers on the
same row, dashed lines link identical values across datasets, showing
club_roster bridging two different emails to one resolved
identity.](reference/figures/identity-graph-bridge.svg)

``` r

library(idmapper)

init_id_envs(c("person", "project"))

dataset_a <- dataset_a %>%
  mark_id(email, graph = "person", type = "email") %>%
  mark_id(uid, graph = "person", type = "uid") %>%
  add_to_identity_graph()

dataset_b <- dataset_b %>%
  mark_id(c(email_from_hr, email_from_email_list), graph = "person", type = "email") %>%
  mark_id(staff_id, graph = "person", type = "staff_id") %>%
  add_to_identity_graph()

generate_master_identity_table()

dataset_a2 <- dataset_a %>% join_master_ids()
dataset_b2 <- dataset_b %>% join_master_ids()
# both now carry a person_UID column; rows that share an identifier
# (directly, or transitively through a third dataset) get the same UID
```

## Package structure

| File | Contents |
|----|----|
| `R/state.R` | Internal identity-graph storage, [`init_id_envs()`](https://gdmcdonald.github.io/idmapper/reference/init_id_envs.md) |
| `R/mark-id.R` | [`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md) |
| `R/build-graph.R` | [`add_to_identity_graph()`](https://gdmcdonald.github.io/idmapper/reference/add_to_identity_graph.md) |
| `R/master-table.R` | [`generate_master_identity_table()`](https://gdmcdonald.github.io/idmapper/reference/generate_master_identity_table.md), [`get_master_table()`](https://gdmcdonald.github.io/idmapper/reference/get_master_table.md) |
| `R/join-ids.R` | [`join_master_ids()`](https://gdmcdonald.github.io/idmapper/reference/join_master_ids.md) |
| `R/filter-ids.R` | [`filter_by_existing_identities()`](https://gdmcdonald.github.io/idmapper/reference/filter_by_existing_identities.md) |
| `R/utils-pipe.R` | Re-exports `%>%` |
| `tests/testthat/` | Regression tests against small synthetic data |
