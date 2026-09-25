#' Attach resolved master IDs onto a dataset
#'
#' For each entity type represented among `df`'s [mark_id()]-marked columns,
#' looks up each row's identifier(s) against that entity type's master
#' identity table (see [generate_master_identity_table()]) and attaches the
#' resolved master ID as a new column (e.g. `person_UID`, `project_UID`).
#'
#' @param df A data frame with one or more columns marked via [mark_id()].
#' @param suffix Suffix appended to each entity type's name to form its new
#'   ID column name (default `"_UID"`, e.g. `"person_UID"`).
#' @param verbose If `TRUE`, print progress messages.
#'
#' @return `df` with one additional column per entity type found among its
#'   marked columns (e.g. `person_UID`), each holding the row's resolved
#'   master ID, or `NA` if none of that row's marked identifiers matched
#'   anything in the master table.
#' @export
join_master_ids <- function(df, suffix = "_UID", verbose = FALSE) {
  # Extract columns with graph attributes
  id_cols <- purrr::map_lgl(df, ~ !is.null(attr(.x, "graph")))

  if (!any(id_cols)) {
    warning("No columns marked with identity attributes found. Returning original dataframe.")
    return(df)
  }

  # Extract all attributes
  col_metadata <- df %>%
    dplyr::select(dplyr::where(~ !is.null(attr(.x, "graph")))) %>%
    purrr::imap_dfr(~ tibble::tibble(
      col_name = .y,
      graph = attr(.x, "graph"),
      id_type = attr(.x, "id_type")
    ))

  # Get all unique graph names
  graph_names <- unique(col_metadata$graph)

  # Start with original dataframe
  result_df <- df

  # Process each graph separately
  for (current_graph in graph_names) {
    if (verbose) cat("Processing", current_graph, "graph...\n")

    # Get master table for this graph
    master <- get_master_table(current_graph)

    # Get columns for this graph from original data
    current_cols <- col_metadata %>%
      dplyr::filter(graph == current_graph) %>%
      dplyr::pull(col_name)

    id_col_name <- paste0(current_graph, "_id")
    id_type_cols <- setdiff(names(master), id_col_name)

    # Create a comprehensive lookup table (vectorized)
    if (verbose) cat("Building lookup table...\n")
    lookup_table <- master %>%
      dplyr::select(dplyr::all_of(c(id_col_name, id_type_cols))) %>%
      tidyr::pivot_longer(
        cols = dplyr::all_of(id_type_cols),
        names_to = "id_type",
        values_to = "id_values"
      ) %>%
      tidyr::unnest(id_values) %>%
      dplyr::filter(!is.na(id_values), id_values != "") %>%
      # Convert to character for joining
      dplyr::mutate(id_values = as.character(id_values)) %>%
      # IMPORTANT: Remove duplicates, keeping first match per combination
      dplyr::distinct(id_type, id_values, .keep_all = TRUE)

    # Prepare data for vectorized matching
    if (verbose) cat("Preparing data for matching...\n")
    df_for_matching <- result_df %>%
      dplyr::select(dplyr::all_of(current_cols)) %>%
      dplyr::mutate(
        .row_id = dplyr::row_number(),
        dplyr::across(dplyr::all_of(current_cols), as.character)
      ) %>%
      tidyr::pivot_longer(
        cols = dplyr::all_of(current_cols),
        names_to = "col_name",
        values_to = "id_value",
        values_drop_na = TRUE
      ) %>%
      dplyr::left_join(
        col_metadata %>% dplyr::filter(graph == current_graph),
        by = "col_name"
      ) %>%
      # Join with lookup table (now guaranteed to have unique matches)
      dplyr::left_join(
        lookup_table,
        by = c("id_type", "id_value" = "id_values")
      ) %>%
      dplyr::filter(!is.na(!!rlang::sym(id_col_name))) %>%
      # Take first match per row
      dplyr::group_by(.row_id) %>%
      dplyr::slice_head(n = 1) %>%
      dplyr::ungroup() %>%
      dplyr::select(.row_id, !!rlang::sym(id_col_name))

    # Join back to main dataframe (vectorized)
    if (verbose) cat("Joining results...\n")
    new_col_name <- paste0(current_graph, suffix)

    # Create a vector for all rows
    matched_ids <- rep(NA_character_, nrow(result_df))
    matched_ids[df_for_matching$.row_id] <- df_for_matching[[id_col_name]]

    # Add the new column
    result_df[[new_col_name]] <- matched_ids

    if (verbose) cat("Completed", current_graph, "- matched", sum(!is.na(matched_ids)), "of", nrow(result_df), "rows\n")
  }

  result_df
}
