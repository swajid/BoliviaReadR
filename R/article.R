#' Parse a La Razon article page
#'
#' Reads a single public article URL and returns a one-row tibble with parsed
#' metadata and article body text.
#'
#' @param url Full article URL.
#' @return A one-row tibble.
#' @export
lr_article <- function(url) {
  if (missing(url) || length(url) != 1 || is.na(url) || !nzchar(url)) {
    rlang::abort("`url` must be a single, non-empty URL string.")
  }

  html <- lr_fetch_html(url)
  out <- lr_parse_article_html(html, url = url)

  if (!nzchar(out$title[[1]]) && !nzchar(out$body[[1]])) {
    rlang::warn("The page was fetched, but article content could not be parsed cleanly.")
  }

  out
}
