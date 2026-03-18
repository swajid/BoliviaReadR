#' Read public headlines from La Razon
#'
#' Fetches public headlines from the homepage or a known section page and
#' returns a tidy tibble.
#'
#' @param section Section slug or label. Defaults to `"portada"`.
#' @param page Page number for paginated section pages.
#' @param n Maximum number of rows to return.
#' @return A tibble of headlines.
#' @export
lr_headlines <- function(section = "portada", page = 1, n = 20) {
  sec <- lr_resolve_section(section)
  path <- sec$path[[1]]
  url <- lr_abs_url(path)

  query <- NULL
  if (!identical(sec$slug[[1]], "portada") && !is.null(page) && page > 1) {
    url <- lr_abs_url(paste0(path, "page/", page, "/"))
  }

  html <- lr_fetch_html(url, query = query)
  out <- lr_parse_listing(html, n = n)

  if (nrow(out) == 0) {
    rlang::warn("No headlines were parsed from the requested page. The site markup may have changed.")
  }

  out
}

#' Shortcut for the homepage latest headlines
#'
#' @param n Maximum number of rows to return.
#' @return A tibble of homepage headlines.
#' @export
lr_latest <- function(n = 20) {
  lr_headlines(section = "portada", n = n)
}
