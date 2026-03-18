\name{lr_article}
\alias{lr_article}
\title{Parse a La Razon article page}
\usage{
lr_article(url)
}
\arguments{
  \item{url}{Full article URL.}
}
\value{A one-row tibble with metadata and article body text.}
\description{Reads a single public article URL and parses its contents.}
