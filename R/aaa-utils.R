lr_base_url <- function() {
  "https://larazon.bo"
}

lr_user_agent <- function() {
  paste(
    "BoliviaReadR/0.1.0",
    "(https://larazon.bo; public-page-reader; contact: local-user)",
    sep = " "
  )
}

lr_abs_url <- function(x) {
  if (length(x) == 0 || is.na(x) || !nzchar(x)) {
    return(NA_character_)
  }

  if (stringr::str_detect(x, "^https?://")) {
    return(x)
  }

  paste0(lr_base_url(), ifelse(startsWith(x, "/"), x, paste0("/", x)))
}

lr_clean_text <- function(x) {
  x <- stringr::str_replace_all(x, "[\r\n\t]+", " ")
  x <- stringr::str_squish(x)
  ifelse(nzchar(x), x, NA_character_)
}

lr_null_if_empty <- function(x) {
  if (length(x) == 0 || all(is.na(x)) || !any(nzchar(stats::na.omit(x)))) {
    return(NULL)
  }
  x
}

lr_pick_text <- function(node, selectors) {
  for (sel in selectors) {
    out <- tryCatch({
      rvest::html_text2(rvest::html_element(node, sel))
    }, error = function(e) NA_character_)

    out <- lr_clean_text(out)
    if (!all(is.na(out)) && nzchar(out[[1]])) {
      return(out[[1]])
    }
  }
  NA_character_
}

lr_pick_attr <- function(node, selectors, attr) {
  for (sel in selectors) {
    out <- tryCatch({
      rvest::html_attr(rvest::html_element(node, sel), attr)
    }, error = function(e) NA_character_)

    out <- lr_clean_text(out)
    if (!all(is.na(out)) && nzchar(out[[1]])) {
      return(out[[1]])
    }
  }
  NA_character_
}

lr_request <- function(url, query = NULL) {
  req <- httr2::request(url) |>
    httr2::req_headers(
      `User-Agent` = lr_user_agent(),
      `Accept-Language` = "es-BO,es;q=0.9,en;q=0.7"
    ) |>
    httr2::req_retry(max_tries = 2) |>
    httr2::req_error(is_error = function(resp) FALSE)

  if (!is.null(query) && length(query) > 0) {
    req <- do.call(httr2::req_url_query, c(list(.req = req), query))
  }

  req
}

lr_fetch_html <- function(url, query = NULL) {
  resp <- lr_request(url, query = query) |>
    httr2::req_perform()

  txt <- httr2::resp_body_string(resp)
  xml2::read_html(txt)
}

lr_fetch_json <- function(url, query = NULL) {
  resp <- lr_request(url, query = query) |>
    httr2::req_perform()

  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

lr_find_article_nodes <- function(html) {
  selectors <- c(
    "main article",
    "article",
    ".post",
    ".jeg_post",
    ".jeg_posts article",
    ".td_module_wrap",
    ".entry",
    ".post-item",
    "[class*='post-']"
  )

  nodes <- list()
  for (sel in selectors) {
    hit <- tryCatch(rvest::html_elements(html, sel), error = function(e) NULL)
    if (!is.null(hit) && length(hit) > 0) {
      nodes[[length(nodes) + 1]] <- hit
    }
  }

  nodes <- unlist(nodes, recursive = FALSE)
  if (length(nodes) == 0) {
    return(nodes)
  }

  urls <- vapply(nodes, function(node) {
    href <- lr_pick_attr(node, c("a[href]"), "href")
    lr_abs_url(href)
  }, character(1))

  keep <- !is.na(urls)
  nodes[keep]
}

lr_parse_teaser_node <- function(node) {
  title <- lr_pick_text(node, c(
    "h1", "h2", "h3", ".entry-title", ".post-title",
    ".jeg_post_title", "a[rel='bookmark']"
  ))

  href <- lr_pick_attr(node, c(
    "h1 a[href]", "h2 a[href]", "h3 a[href]", "a[rel='bookmark']",
    ".entry-title a[href]", ".post-title a[href]", "a[href]"
  ), "href")

  section <- lr_pick_text(node, c(
    ".meta-category a", ".jeg_meta_category a", "a[rel='category tag']",
    ".category a", ".cat-links a"
  ))

  published <- lr_pick_attr(node, c("time"), "datetime")
  if (is.na(published)) {
    published <- lr_pick_text(node, c("time", ".date", ".entry-date", ".jeg_meta_date"))
  }

  summary <- lr_pick_text(node, c(
    ".entry-summary", ".excerpt", ".jeg_post_excerpt", "p"
  ))

  image <- lr_pick_attr(node, c("img"), "src")

  tibble::tibble(
    title = title,
    section = section,
    published = published,
    summary = summary,
    url = lr_abs_url(href),
    image = lr_abs_url(image)
  )
}

lr_parse_listing <- function(html, n = Inf) {
  nodes <- lr_find_article_nodes(html)
  if (length(nodes) == 0) {
    return(tibble::tibble(
      title = character(),
      section = character(),
      published = character(),
      summary = character(),
      url = character(),
      image = character()
    ))
  }

  out <- purrr::map_dfr(nodes, lr_parse_teaser_node)
  out <- dplyr::filter(out, !is.na(.data$url), !is.na(.data$title))
  out <- dplyr::distinct(out, .data$url, .keep_all = TRUE)

  if (is.finite(n)) {
    out <- utils::head(out, n)
  }

  out
}

lr_parse_article_html <- function(html, url = NA_character_) {
  title <- lr_pick_text(html, c("meta[property='og:title']", "h1", ".entry-title", ".post-title"))
  if (is.na(title)) {
    title <- lr_pick_attr(html, c("meta[property='og:title']"), "content")
  }

  subtitle <- lr_pick_text(html, c(
    "h2", ".subtitle", ".entry-subtitle", ".bajada", ".excerpt"
  ))

  author <- lr_pick_text(html, c(
    "[rel='author']", ".author", ".byline", ".jeg_meta_author a"
  ))

  published <- lr_pick_attr(html, c(
    "meta[property='article:published_time']", "time"
  ), "content")
  if (is.na(published)) {
    published <- lr_pick_attr(html, c("time"), "datetime")
  }
  if (is.na(published)) {
    published <- lr_pick_text(html, c("time", ".date", ".entry-date"))
  }

  updated <- lr_pick_attr(html, c(
    "meta[property='article:modified_time']"
  ), "content")

  section <- lr_pick_text(html, c(
    "a[rel='category tag']", ".meta-category a", ".breadcrumb a:last-child"
  ))

  tag_nodes <- tryCatch(
    rvest::html_elements(html, "a[rel='tag'], .tags a, .tagcloud a"),
    error = function(e) NULL
  )
  tags <- if (is.null(tag_nodes) || length(tag_nodes) == 0) character(0) else lr_clean_text(rvest::html_text2(tag_nodes))
  tags <- unique(stats::na.omit(tags))

  body_selectors <- c(
    ".entry-content p",
    ".post-content p",
    ".article-content p",
    ".content p",
    "article p"
  )

  paragraphs <- character(0)
  for (sel in body_selectors) {
    p <- tryCatch(rvest::html_elements(html, sel), error = function(e) NULL)
    if (!is.null(p) && length(p) > 0) {
      paragraphs <- lr_clean_text(rvest::html_text2(p))
      paragraphs <- unique(stats::na.omit(paragraphs))
      if (length(paragraphs) > 0) break
    }
  }

  tibble::tibble(
    title = title,
    subtitle = subtitle,
    author = author,
    published = published,
    updated = updated,
    section = section,
    url = lr_abs_url(url),
    body = paste(paragraphs, collapse = "\n\n"),
    tags = list(tags),
    paragraphs = list(paragraphs)
  )
}
