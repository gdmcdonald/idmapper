#' Collapse an identity graph into a master identity table
#'
#' Finds the connected components of an entity type's identity graph (built
#' up via repeated [add_to_identity_graph()] calls) and collapses each
#' component into a single master identity, assigned an ID like
#' `"PERSON-1"`, `"PERSON-2"`, .... The resulting table has one row per
#' master identity and one list-column per distinct `id_type` seen (e.g.
#' `email`, `unikey`), each holding every identifier value that resolved to
#' that identity.
#'
#' @param env_name Optional entity type name (e.g. `"person"`). If `NULL`
#'   (the default), a master table is generated for every entity type
#'   currently initialised via [init_id_envs()], returned as a named list.
#' @param verbose If `TRUE` (the default), print progress messages.
#' @param id_prefix Prefix used for generated master IDs. Defaults to the
#'   upper-cased `env_name` followed by `"-"` (e.g. `"PERSON-"`).
#' @param store_in_env If `TRUE` (the default), also store the resulting
#'   table so [get_master_table()] can retrieve it later without
#'   regenerating it.
#'
#' @return A tibble with one row per master identity: an ID column named
#'   `"<env_name>_id"`, and one list-column per `id_type` found in the
#'   graph. If `env_name` is `NULL`, a named list of such tibbles, one per
#'   entity type.
#' @export
generate_master_identity_table <- function(env_name = NULL, verbose = TRUE,
                                            id_prefix = NULL, store_in_env = TRUE) {

  # If no env_name specified, generate for all environments
  if (is.null(env_name)) {
    env_names <- list_id_envs()

    # Generate tables for all environments
    results <- purrr::map(env_names, ~ generate_master_identity_table(.x, verbose, store_in_env = store_in_env))
    names(results) <- env_names
    return(results)
  }

  # Single environment processing
  env <- get_id_env(env_name)
  g <- env$graph

  if (verbose) cat("Processing", env_name, "graph...\n")

  # Handle empty graph
  if (igraph::vcount(g) == 0) {
    if (verbose) cat("Empty graph - returning empty table\n")
    empty_table <- tibble::tibble(!!paste0(env_name, "_id") := character(0))
    if (store_in_env) env$master_table <- empty_table
    return(empty_table)
  }

  if (verbose) cat("Extracting vertex data...\n")
  node_ids <- igraph::V(g)$name
  id_type_vec <- igraph::vertex_attr(g, "id_type")
  id_value_vec <- igraph::vertex_attr(g, "id_value")

  if (verbose) cat("Computing components...\n")
  comps <- igraph::components(g)

  # Create the base dataframe
  df <- tibble::tibble(
    node_id = node_ids,
    component = comps$membership,
    id_type = id_type_vec,
    id_value = id_value_vec
  )

  # Get all unique ID types
  id_types <- unique(df$id_type)
  if (verbose) cat("ID types found:", paste(id_types, collapse = ", "), "\n")

  # Create the wide format with nested columns
  if (is.null(id_prefix)) {
    id_prefix <- paste0(stringr::str_to_upper(env_name), "-")
  }

  # Create base table with ID and nested data
  base_table <- df %>%
    dplyr::group_by(component) %>%
    dplyr::summarise(
      !!paste0(env_name, "_id") := paste0(id_prefix, dplyr::cur_group_id()),
      id_data = list(tibble::tibble(id_type = id_type, id_value = id_value)),
      .groups = "drop"
    )

  # Create columns for each ID type
  for (id_type in id_types) {
    base_table <- base_table %>%
      dplyr::mutate(
        !!id_type := purrr::map(id_data, ~ {
          type_data <- .x %>% dplyr::filter(id_type == !!id_type)
          if (nrow(type_data) > 0) type_data$id_value else character(0)
        })
      )
  }

  # Clean up and finalize - remove id_data and component
  master_table <- base_table %>%
    dplyr::select(-id_data, -component)

  if (verbose) {
    cat("Generated master table with", nrow(master_table), "entities\n")
    cat("Preview:\n")
    print(head(master_table))
  }

  # Store in environment if requested
  if (store_in_env) {
    env$master_table <- master_table
    if (verbose) cat("Stored master table for '", env_name, "'\n", sep = "")
  }

  master_table
}

#' Retrieve a previously generated master identity table
#'
#' @param env_name Entity type name (e.g. `"person"`, `"project"`).
#'
#' @return The tibble previously stored by
#'   [generate_master_identity_table()] for this entity type.
#' @export
get_master_table <- function(env_name) {
  env <- get_id_env(env_name)
  if (is.null(env$master_table)) {
    stop(
      "No master table found for '", env_name,
      "'. Run generate_master_identity_table() first.",
      call. = FALSE
    )
  }
  env$master_table
}
