#' Search La Razon public pages
#'
#' Performs a WordPress-style site search using the `s` query parameter.
#' This works on many WordPress-based public sites and is included here as a
#' best-effort convenience wrapper.
#'
#' @param query Search string.
#' @param page Page number.
#' @param n Maximum number of rows to return.
#' @return A tibble of matching headlines.
#' @export
lr_search <- function(query, page = 1, n = 20) {
  if (missing(query) || is.na(query) || !nzchar(query)) {
    rlang::abort("`query` must be a non-empty string.")
  }

  html <- lr_fetch_html(
    lr_base_url(),
    query = list(s = query, page = page)
  )

  out <- lr_parse_listing(html, n = n)

  if (nrow(out) == 0) {
    rlang::warn("Search completed but no stories were parsed from the response.")
  }

  out
}
