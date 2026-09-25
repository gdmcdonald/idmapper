#' Restrict a dataset to rows matching an existing identity graph
#'
#' Keeps only the rows of `df` that have at least one marked identifier
#' already present in an entity type's identity graph - without adding any
#' new identifiers or edges to that graph. Useful for datasets you want to
#' enrich/cross-check against known identities (e.g. an LDAP extract) but
#' not treat as a source of new identity links.
#'
#' @param df A data frame with one or more columns marked via [mark_id()].
#' @param env_name Entity type name to check against (default `"person"`).
#' @param verbose If `TRUE`, print how many rows were kept.
#'
#' @return `df`, filtered to rows with at least one matching identifier for
#'   `env_name`. If that entity type's graph is empty, or `df` has no
#'   marked columns for it, returns a zero-row slice of `df`.
#' @export
filter_by_existing_identities <- function(df, env_name = "person", verbose = FALSE) {
  # Get existing identities
  env <- get_id_env(env_name)
  g <- env$graph

  if (igraph::vcount(g) == 0) {
    return(df %>% dplyr::slice(0))
  }

  # Create lookup by ID type
  existing_lookup <- tibble::tibble(
    id_type = igraph::vertex_attr(g, "id_type"),
    id_value = as.character(igraph::vertex_attr(g, "id_value"))
  ) %>%
    dplyr::group_by(id_type) %>%
    dplyr::summarise(values = list(unique(id_value)), .groups = "drop")

  # Get columns for this graph
  id_cols <- df %>%
    dplyr::select(dplyr::where(~ !is.null(attr(.x, "graph")) && attr(.x, "graph") == env_name))

  if (ncol(id_cols) == 0) {
    return(df %>% dplyr::slice(0))
  }

  col_metadata <- id_cols %>%
    purrr::imap_dfr(~ tibble::tibble(col_name = .y, id_type = attr(.x, "id_type")))

  # Simple approach: check each column type individually
  df_with_matches <- df

  for (i in seq_len(nrow(col_metadata))) {
    col_name <- col_metadata$col_name[i]
    id_type <- col_metadata$id_type[i]

    valid_values <- existing_lookup %>%
      dplyr::filter(id_type == !!id_type) %>%
      dplyr::pull(values) %>%
      unlist()

    if (length(valid_values) > 0) {
      df_with_matches <- df_with_matches %>%
        dplyr::mutate(
          !!paste0(col_name, "_match") := as.character(!!rlang::sym(col_name)) %in% valid_values
        )
    }
  }

  # Filter to rows with at least one match
  match_cols <- names(df_with_matches)[stringr::str_ends(names(df_with_matches), "_match")]

  result <- df_with_matches %>%
    dplyr::filter(dplyr::if_any(dplyr::all_of(match_cols), ~ .x == TRUE)) %>%
    dplyr::select(-dplyr::all_of(match_cols)) # Remove the helper columns

  if (verbose) {
    cat("Filtered from", nrow(df), "to", nrow(result), "rows\n")
  }

  result
}
