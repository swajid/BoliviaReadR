\name{lr_headlines}
\alias{lr_headlines}
\alias{lr_latest}
\title{Read public headlines from La Razon}
\usage{
lr_headlines(section = "portada", page = 1, n = 20)

lr_latest(n = 20)
}
\arguments{
  \item{section}{Section slug or label.}
  \item{page}{Page number for paginated section pages.}
  \item{n}{Maximum number of rows to return.}
}
\value{A tibble of headlines.}
\description{Fetches public headlines from the homepage or a known section page.}
