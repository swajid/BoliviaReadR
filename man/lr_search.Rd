\name{lr_search}
\alias{lr_search}
\title{Search La Razon public pages}
\usage{
lr_search(query, page = 1, n = 20)
}
\arguments{
  \item{query}{Search string.}
  \item{page}{Page number.}
  \item{n}{Maximum number of rows to return.}
}
\value{A tibble of matching stories.}
\description{Performs a WordPress-style public site search using the \code{s} query parameter.}
