#' Known public La Razon sections
#'
#' Returns a built-in tibble of La Razon section names and URL paths used by
#' the package. These are based on the site's public structure and may evolve
#' over time.
#'
#' @return A tibble with section labels, slugs, and paths.
#' @export
lr_sections <- function() {
  tibble::tibble(
    section = c(
      "Portada",
      "Opinion",
      "Economia y Empresa",
      "Nacional",
      "Mundo",
      "Ciudades",
      "Sociedad",
      "Espacio Empresarial",
      "La Revista",
      "Marcas",
      "Sociales",
      "Animal Politico"
    ),
    slug = c(
      "portada",
      "opinion",
      "economia-y-empresa",
      "nacional",
      "mundo",
      "ciudades",
      "sociedad",
      "espacio-empresarial",
      "la-revista",
      "marcas",
      "sociales",
      "politico"
    ),
    path = c(
      "/",
      "/opinion/",
      "/economia-y-empresa/",
      "/nacional/",
      "/mundo/",
      "/ciudades/",
      "/sociedad/",
      "/espacio-empresarial/",
      "/la-revista/",
      "/marcas/",
      "/sociales/",
      "/politico/"
    )
  )
}

lr_resolve_section <- function(section = "portada") {
  sections <- lr_sections()

  if (is.null(section) || is.na(section) || !nzchar(section)) {
    section <- "portada"
  }

  section <- tolower(section)
  hit <- sections[sections$slug == section | tolower(sections$section) == section, , drop = FALSE]

  if (nrow(hit) == 0) {
    rlang::abort(
      paste0(
        "Unknown section: '", section, "'. Use one of: ",
        paste(sections$slug, collapse = ", ")
      )
    )
  }

  hit
}
