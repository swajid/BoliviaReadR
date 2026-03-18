#' Check whether a public WordPress JSON API appears available
#'
#' @return Logical scalar.
#' @export
lr_wp_available <- function() {
  ok <- tryCatch({
    x <- lr_fetch_json(paste0(lr_base_url(), "/wp-json/"))
    is.list(x) || is.data.frame(x)
  }, error = function(e) FALSE)

  isTRUE(ok)
}

lr_wp_find_category_id <- function(section) {
  sec <- lr_resolve_section(section)
  cats <- lr_fetch_json(
    paste0(lr_base_url(), "/wp-json/wp/v2/categories"),
    query = list(search = sec$section[[1]], per_page = 100)
  )

  if (is.null(cats) || NROW(cats) == 0) {
    return(NULL)
  }

  if (!is.data.frame(cats)) {
    cats <- as.data.frame(cats, stringsAsFactors = FALSE)
  }

  if (!"slug" %in% names(cats)) {
    return(NULL)
  }

  hit <- cats[cats$slug == sec$slug[[1]], , drop = FALSE]
  if (nrow(hit) == 0) {
    hit <- cats[1, , drop = FALSE]
  }

  hit$id[[1]]
}

#' Read posts from public WordPress JSON endpoints when available
#'
#' This function attempts to use the site's public WordPress API. If the API is
#' unavailable or restricted, it errors and you can fall back to `lr_headlines()`.
#'
#' @param section Optional section slug.
#' @param page Page number.
#' @param per_page Number of posts per page.
#' @return A tibble of posts.
#' @export
lr_wp_posts <- function(section = NULL, page = 1, per_page = 10) {
  if (!lr_wp_available()) {
    rlang::abort("Public WordPress JSON endpoints do not appear to be available.")
  }

  query <- list(page = page, per_page = per_page)
  if (!is.null(section)) {
    cat_id <- lr_wp_find_category_id(section)
    if (!is.null(cat_id)) {
      query$categories <- cat_id
    }
  }

  posts <- lr_fetch_json(
    paste0(lr_base_url(), "/wp-json/wp/v2/posts"),
    query = query
  )

  if (!is.data.frame(posts)) {
    posts <- as.data.frame(posts, stringsAsFactors = FALSE)
  }

  title <- rep(NA_character_, nrow(posts))
  excerpt <- rep(NA_character_, nrow(posts))

  if ("title.rendered" %in% names(posts)) {
    title <- lr_clean_text(posts[["title.rendered"]])
  } else if ("title" %in% names(posts) && is.list(posts$title)) {
    title <- lr_clean_text(vapply(posts$title, function(x) x$rendered %||% NA_character_, character(1)))
  }

  if ("excerpt.rendered" %in% names(posts)) {
    excerpt <- lr_clean_text(gsub("<[^>]+>", " ", posts[["excerpt.rendered"]]))
  }

  tibble::tibble(
    id = if ("id" %in% names(posts)) posts$id else NA_integer_,
    published = if ("date" %in% names(posts)) posts$date else NA_character_,
    slug = if ("slug" %in% names(posts)) posts$slug else NA_character_,
    title = title,
    summary = excerpt,
    url = if ("link" %in% names(posts)) posts$link else NA_character_
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
