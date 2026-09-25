#' idmapper: Entity Resolution and Identity Graphs Across Multiple Data Sources
#'
#' Resolve the same real-world entity (for example a person or a project) as
#' it appears under different identifiers (email address, staff ID, unikey,
#' project shortcode, and so on) across multiple, separately maintained data
#' sources.
#'
#' The typical workflow is:
#'
#' 1. [init_id_envs()] once, naming each entity type you want to resolve
#'    (e.g. `"person"`, `"project"`).
#' 2. For each raw dataset, [mark_id()] the columns that carry an identifier
#'    for one of those entity types, then pipe into
#'    [add_to_identity_graph()]. Two identifiers become linked whenever they
#'    co-occur on the same row of the same dataset (e.g. an email and a
#'    unikey that appear together are assumed to belong to the same
#'    person).
#' 3. Once every dataset has been added, call
#'    [generate_master_identity_table()] once to collapse each connected
#'    component of the identity graph into a single master ID.
#' 4. Use [join_master_ids()] on any (marked) dataset to attach the
#'    resulting master ID as a new column, or [get_master_table()] to pull
#'    the master table itself.
#' 5. [filter_by_existing_identities()] is a convenience for restricting a
#'    new dataset (e.g. an LDAP extract) to only the identities already
#'    known to a graph, without adding any new ones.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

# Symbols referenced via NSE inside dplyr/tidyr pipelines below - declared
# here so R CMD check doesn't flag them as undefined globals.
utils::globalVariables(c(
  "col_name", "graph", "id_type", "id_value", "id_values", "id_data",
  "node_id", "component", "row_id", ".row_id"
))
