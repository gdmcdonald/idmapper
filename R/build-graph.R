#' Add a marked dataset to its identity graph(s)
#'
#' Reads the `graph`/`id_type` attributes set by [mark_id()] on `df`'s
#' columns, and for each entity type found:
#' \enumerate{
#'   \item treats every distinct `(id_type, id_value)` pair across all
#'     marked columns as a node (creating any that don't already exist);
#'   \item for any row where two or more of those nodes co-occur, adds an
#'     edge between every pair of them, on the assumption that identifiers
#'     appearing together on the same row belong to the same real-world
#'     entity.
#' }
#' Repeated calls across multiple datasets accumulate into the same graph,
#' which is what lets [generate_master_identity_table()] later resolve a
#' single master identity across sources that never share a common key
#' directly, but are transitively linked through others that do.
#'
#' @param df A data frame with one or more columns marked via [mark_id()].
#' @param env_name Optional character vector restricting processing to
#'   these entity types only (by default, every entity type found among
#'   `df`'s marked columns is processed).
#' @param debug If `TRUE`, print diagnostic information about the columns,
#'   nodes, and edges being processed.
#'
#' @return Invisibly, `df` (unchanged), so this can be used at the end of a
#'   pipe purely for its side effect of updating the relevant identity
#'   graph(s).
#' @export
add_to_identity_graph <- function(df, env_name = NULL, debug = FALSE) {
  # Extract columns with graph attributes
  id_cols <- purrr::map_lgl(df, ~ !is.null(attr(.x, "graph")))

  if (!any(id_cols)) {
    stop("No columns marked with identity attributes found. Use mark_id() first.")
  }

  # Extract all attributes upfront before any data manipulation
  col_metadata <- df %>%
    dplyr::select(dplyr::where(~ !is.null(attr(.x, "graph")))) %>%
    purrr::imap_dfr(~ tibble::tibble(
      col_name = .y,
      graph = attr(.x, "graph"),
      id_type = attr(.x, "id_type")
    ))

  if (debug) {
    cat("Column metadata:\n")
    print(col_metadata)
  }

  # Get all unique graph names
  graph_names <- unique(col_metadata$graph)

  # If env_name is specified, only process that graph
  if (!is.null(env_name)) {
    graph_names <- intersect(graph_names, env_name)
  }

  # Process each graph separately
  for (current_graph in graph_names) {
    if (debug) cat("\nProcessing graph:", current_graph, "\n")

    # Get the environment
    env <- get_id_env(current_graph)

    # Get columns for this graph
    current_cols <- col_metadata %>%
      dplyr::filter(graph == current_graph) %>%
      dplyr::pull(col_name)

    if (debug) cat("Columns for this graph:", paste(current_cols, collapse = ", "), "\n")

    # Select and convert to character
    df_subset <- df %>%
      dplyr::select(dplyr::all_of(current_cols)) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))

    # Create long format and join with metadata
    df_long <- df_subset %>%
      dplyr::mutate(row_id = dplyr::row_number()) %>%
      tidyr::pivot_longer(
        cols = -row_id, names_to = "col_name", values_to = "id_value",
        values_drop_na = TRUE
      ) %>%
      dplyr::left_join(col_metadata, by = "col_name") %>%
      dplyr::distinct(row_id, id_type, id_value) %>%
      dplyr::mutate(node_id = paste0(id_type, "||", id_value))

    if (debug) {
      cat("First few rows of df_long:\n")
      print(head(df_long, 10))

      # Check for problematic rows
      row_counts <- df_long %>%
        dplyr::group_by(row_id) %>%
        dplyr::summarise(n_unique_nodes = dplyr::n_distinct(node_id), .groups = "drop")

      single_node_rows <- row_counts %>% dplyr::filter(n_unique_nodes < 2)
      multi_node_rows <- row_counts %>% dplyr::filter(n_unique_nodes >= 2)

      cat("Rows with < 2 unique nodes:", nrow(single_node_rows), "\n")
      cat("Rows with >= 2 unique nodes:", nrow(multi_node_rows), "\n")
    }

    # Create edges - handle the case where no rows have 2+ nodes
    rows_with_multiple_nodes <- df_long %>%
      dplyr::group_by(row_id) %>%
      dplyr::filter(dplyr::n_distinct(node_id) >= 2) %>%
      dplyr::ungroup()

    if (nrow(rows_with_multiple_nodes) > 0) {
      edge_list <- rows_with_multiple_nodes %>%
        dplyr::group_by(row_id) %>%
        dplyr::reframe(pairs = combn(unique(node_id), 2, simplify = FALSE)) %>%
        dplyr::pull(pairs) %>%
        unlist(recursive = FALSE)
    } else {
      edge_list <- list() # Empty list if no edges to create
      if (debug) cat("No rows with multiple nodes - no edges to create\n")
    }

    if (debug) cat("Number of edges to add:", length(edge_list), "\n")

    g <- env$graph

    all_nodes <- df_long %>%
      dplyr::distinct(node_id, id_type, id_value)

    existing_nodes <- igraph::V(g)$name
    new_nodes <- all_nodes %>%
      dplyr::filter(!node_id %in% existing_nodes)

    if (debug) cat("New nodes to add:", nrow(new_nodes), "\n")

    # Add new vertices with attributes
    if (nrow(new_nodes) > 0) {
      g <- g + igraph::vertices(
        new_nodes$node_id,
        id_type = new_nodes$id_type,
        id_value = new_nodes$id_value
      )
    }

    # Add new edges
    if (length(edge_list) > 0) {
      g <- g + igraph::edges(unlist(edge_list))
    }

    env$graph <- g

    if (debug) {
      cat("Graph now has", igraph::vcount(g), "vertices and", igraph::ecount(g), "edges\n")
    }
  }

  invisible(df) # Return original df for piping
}
