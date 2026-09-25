# Internal package state --------------------------------------------------
#
# idmapper needs to remember one identity graph (and, once built, one master
# identity table) per named entity type across many calls - e.g. a "person"
# graph and a "project" graph, built up incrementally as each raw dataset is
# added. That state lives here, in a single environment private to the
# package, rather than being written into the caller's .GlobalEnv the way
# the original id_map.R script did (which stored it as loose `person_env`,
# `project_env`, ... variables). Storing it privately means idmapper behaves
# the same whether it's called from a script, a function, an R Markdown
# chunk, or anywhere else - and it can't collide with an unrelated object
# the caller happens to have named `person_env`.
.idmapper_state <- new.env(parent = emptyenv())

#' Initialise identity graph environments
#'
#' Creates one empty identity graph per named entity type (for example
#' `"person"`, `"project"`). Must be called before [mark_id()] /
#' [add_to_identity_graph()] for a given entity type, and is safe to call
#' again later to reset a type back to an empty graph.
#'
#' @param names Character vector of entity type names to initialise.
#' @param suffix Kept only for backwards compatibility with the original
#'   `id_map.R` script's argument list; no longer used, since state is now
#'   stored internally rather than as `<name>_env` variables in a target
#'   environment.
#' @param envir Kept only for backwards compatibility; ignored. State is
#'   always stored in an internal package environment now, never in
#'   `envir`.
#' @param init_graph If `TRUE` (the default), initialise each entity type
#'   with an empty, undirected graph ([igraph::make_empty_graph()]).
#'
#' @return Invisibly, `NULL`. Called for its side effect of creating (or
#'   resetting) package-internal state for each entity type in `names`.
#' @export
#'
#' @examples
#' init_id_envs(c("person", "project"))
init_id_envs <- function(names = c("person", "project", "organisation"),
                          suffix = "_env",
                          envir = NULL,
                          init_graph = TRUE) {
  for (name in names) {
    env <- new.env(parent = emptyenv())

    if (init_graph) {
      env$graph <- igraph::make_empty_graph(directed = FALSE)
    }

    assign(name, env, envir = .idmapper_state)
  }

  invisible(NULL)
}

# Internal: fetch the environment for a given entity type. Errors with a
# pointer back to init_id_envs() if that type hasn't been initialised yet,
# rather than failing with a confusing "object not found".
get_id_env <- function(env_name) {
  if (!exists(env_name, envir = .idmapper_state, inherits = FALSE)) {
    stop(
      "No identity graph found for entity type '", env_name, "'. ",
      "Call init_id_envs(\"", env_name, "\") first.",
      call. = FALSE
    )
  }
  get(env_name, envir = .idmapper_state, inherits = FALSE)
}

# Internal: list entity types currently initialised (used by
# generate_master_identity_table() when no env_name is supplied).
list_id_envs <- function() {
  ls(envir = .idmapper_state)
}
