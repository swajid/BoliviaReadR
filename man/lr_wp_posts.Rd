\name{lr_wp_available}
\alias{lr_wp_available}
\alias{lr_wp_posts}
\title{Work with public WordPress JSON endpoints when available}
\usage{
lr_wp_available()

lr_wp_posts(section = NULL, page = 1, per_page = 10)
}
\arguments{
  \item{section}{Optional section slug.}
  \item{page}{Page number.}
  \item{per_page}{Number of posts per page.}
}
\value{\code{lr_wp_available()} returns a logical scalar. \code{lr_wp_posts()} returns a tibble.}
\description{Helpers for optional WordPress JSON API access when the site exposes it publicly.}
