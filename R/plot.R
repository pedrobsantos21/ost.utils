#' Custom ggplot2 Theme for Detran Visualizations
#'
#' @description
#' Provides a custom ggplot2 theme with a minimal base, adjusted legend
#' positioning, and other aesthetic modifications suitable for Detran-related
#' data visualizations.
#'
#' @param size base font size, given in pts.
#' @param family base font family.
#' @param ... Additional arguments passed to `ggplot2::theme()`.
#'
#' @return A `ggplot2` theme object.
#' @export
#' @importFrom ggplot2 theme_minimal theme
theme_detran <- function(size = 11, family = "", ...) {
    ggplot2::theme_minimal(base_size = size, base_family = family) +
        ggplot2::theme(
            legend.position = "top",
            legend.justification = "left",
            legend.key.size = ggplot2::unit(0.5, "cm"),
            legend.direction = "horizontal",
            ...
        )
}

#' Detran Color Palette
#'
#' @description
#' Provides a list of hex color codes representing the official Detran color palette.
#'
#' @return A named list of character strings, where each string is a hex color code.
#' @export
palette_detran <- function() {
    list(
        "lightpurple" = "#D3A1FA",
        "purple" = "#B456E0",
        "darkpurple" = "#390077",
        "lightblue" = "#A4CFED",
        "blue" = "#005CA8",
        "darkblue" = "#004077",
        "grey" = "#8C8C8C"
    )
}
