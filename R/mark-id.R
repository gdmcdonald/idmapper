#' Mark identity columns for entity resolution
#'
#' Tags one or more columns of `df` with attributes recording which entity
#' graph they belong to (e.g. `"person"`, `"project"`) and what kind of
#' identifier they represent (e.g. `"email"`, `"unikey"`). These attributes
#' are read later by [add_to_identity_graph()] (to build the identity graph)
#' and [join_master_ids()] (to attach a resolved master ID back onto `df`).
#'
#' @param df A data frame.
#' @param cols One column, or several columns wrapped in `c()`, to mark.
#'   Uses tidy evaluation, so bare column names work directly:
#'   `mark_id(df, email, graph = "person", type = "email")` or
#'   `mark_id(df, c(email_from_hr, email_from_irma), graph = "person", type = "email")`.
#' @param graph Name of the entity graph this identifier belongs to. Should
#'   match a name previously passed to [init_id_envs()].
#' @param type A label for this kind of identifier (e.g. `"email"`,
#'   `"unikey"`, `"staff_id"`). Two values are only ever considered
#'   candidates for the same identity if they share an `id_type`.
#' @param exact Currently unused; reserved for future fuzzy-matching
#'   support.
#'
#' @return `df`, with `graph` and `id_type` attributes attached to the
#'   marked column(s). No rows or columns are added, removed, or reordered.
#' @export
#'
#' @examples
#' df <- data.frame(email = c("a@example.com", "b@example.com"))
#' df <- mark_id(df, email, graph = "person", type = "email")
#' attr(df$email, "graph")
#' attr(df$email, "id_type")
mark_id <- function(df, cols, graph = "person", type, exact = TRUE) {
  cols_expr <- rlang::enquo(cols)

  # Handle multiple columns
  if (rlang::quo_is_call(cols_expr, c("c", "list"))) {
    # Extract column names from c(...) expression
    col_names <- as.character(rlang::call_args(rlang::quo_get_expr(cols_expr)))
  } else {
    # Single column
    col_names <- as.character(rlang::quo_get_expr(cols_expr))
  }

  # Verify columns exist
  missing_cols <- setdiff(col_names, names(df))
  if (length(missing_cols) > 0) {
    stop("Columns not found: ", paste(missing_cols, collapse = ", "))
  }

  # Apply attributes to each specified column
  df %>%
    dplyr::mutate(dplyr::across(
      dplyr::all_of(col_names),
      ~ {
        attr(.x, "graph") <- graph
        attr(.x, "id_type") <- type
        .x
      }
    ))
}
