#' Load Infosiga Data from a ZIP File
#'
#' Extracts and loads Infosiga data from a ZIP file containing CSV files.
#' The function supports loading data on traffic incidents, people, or vehicles.
#'
#' @param file_type Character string specifying the type of file to load.
#'   Must be one of:
#'   \itemize{
#'     \item `"sinistros"` — incident-level data
#'     \item `"pessoas"` — person-level data
#'     \item `"veiculos"` — vehicle-level data
#'   }
#' @param zip_path Path to the ZIP file containing the Infosiga dataset.
#'
#' @return A data frame containing the loaded Infosiga data.
#'
#' @details
#' The function extracts the ZIP file into a temporary directory, locates
#' the corresponding CSV file based on the selected \code{file_type},
#' and reads it using \pkg{readr}. Files are expected to be encoded
#' in Latin-1. If the ZIP contains a subdirectory named
#' \code{dados_infosiga}, the function automatically navigates into it.
#'
#' @examples
#' \dontrun{
#' df <- load_infosiga(
#'     file_type = "sinistros",
#'     zip_path = "path/to/infosiga_data.zip"
#' )
#' }
#'
#' @export
load_infosiga <- function(
    file_type = c("sinistros", "pessoas", "veiculos"),
    zip_path
) {
    tempdir <- tempdir()
    utils::unzip(zipfile = zip_path, exdir = tempdir)
    if (fs::dir_exists(glue::glue("{tempdir}/dados_infosiga"))) {
        tempdir <- fs::path(tempdir, "dados_infosiga")
    }

    files <- list.files(
        tempdir,
        pattern = glue::glue("^{file_type}"),
        full.names = TRUE
    )

    df <- readr::read_csv2(files, locale = readr::locale(encoding = "latin1"))
    on.exit(unlink(tempdir))
    return(df)
}

#' Clean and Standardize Raw Infosiga Data
#'
#' @description
#' This function processes a raw data frame from Infosiga, applying specific
#' cleaning and transformation rules based on the type of data (`sinistros`,
#' `pessoas`, or `veiculos`).
#'
#' @details
#' The function performs a series of data cleaning tasks, including:
#' - **Standardizing categorical variables:** Recodes text values to a
#'   consistent format (e.g., "SINISTRO FATAL" to "Sinistro fatal").
#' - **Type conversion:** Converts columns to their appropriate types, such as
#'   dates (`lubridate::dmy`), numbers, and factors with ordered levels (e.g.,
#'   age groups).
#' - **Handling missing values:** Replaces "NAO DISPONIVEL" strings with `NA`.
#' - **Joining with external data:** Merges the data with an internal
#'   municipalities dataset (`municipios`) to add geographical information like
#'   IBGE codes and administrative regions.
#' - **Column renaming and selection:** Renames columns for clarity (e.g.,
#'   `ano_fab` to `ano_fabricacao`) and selects a final set of relevant
#'   variables, dropping intermediate or raw ones.
#'
#' The specific cleaning pipeline applied depends on the `file_type` argument.
#'
#' @param df_infosiga A raw data frame as loaded by `load_infosiga()`.
#' @param file_type A string indicating the type of data to be cleaned. Must be
#'   one of `'sinistros'`, `'pessoas'`, or `'veiculos'`.
#'
#' @return A cleaned and processed `tibble` with standardized columns and types.
#'
#' @export
#' @importFrom dplyr mutate case_match across starts_with if_else left_join select rename
#' @importFrom lubridate dmy
#' @importFrom stringr str_replace_all
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' # First, download and load the data
#' data_dir <- tempdir()
#' download_infosiga(destpath = data_dir)
#' raw_sinistros_df <- load_infosiga(file_type = "sinistros", path = data_dir)
#'
#' # Clean the 'sinistros' data
#' cleaned_sinistros_df <- clean_infosiga(raw_sinistros_df, file_type = "sinistros")
#'
#' # Clean the 'pessoas' data
#' raw_pessoas_df <- load_infosiga(file_type = "pessoas", path = data_dir)
#' cleaned_pessoas_df <- clean_infosiga(raw_pessoas_df, file_type = "pessoas")
#' }
clean_infosiga <- function(
    df_infosiga,
    file_type = c("sinistros", "pessoas", "veiculos")
) {
    if (file_type == "sinistros") {
        df <- df_infosiga |>
            dplyr::mutate(
                tipo_registro = dplyr::case_match(
                    .data$tipo_registro,
                    "SINISTRO FATAL" ~ "Sinistro fatal",
                    "SINISTRO NAO FATAL" ~ "Sinistro n\u00e3o fatal",
                    "NOTIFICACAO" ~ "Notifica\u00e7\u00e3o",
                ),
                data_sinistro = lubridate::dmy(.data$data_sinistro),
                turno = stringr::str_to_sentence(.data$turno),
                numero_logradouro = as.numeric(.data$numero_logradouro),
                tipo_via = stringr::str_to_sentence(.data$tipo_via),
                tipo_via = if_else(
                    .data$tipo_via == "Nao disponivel",
                    NA,
                    .data$tipo_via
                ),
                dplyr::across(
                    .data$qtd_pedestre:.data$qtd_gravidade_nao_disponivel,
                    ~ dplyr::if_else(is.na(.x), 0, .x)
                ),
                administracao = dplyr::case_match(
                    .data$administracao,
                    "NAO DISPONIVEL" ~ NA,
                    .default = .data$administracao
                ),
                circunscricao = dplyr::case_match(
                    .data$circunscricao,
                    "ESTADUAL" ~ "Estadual",
                    "MUNICIPAL" ~ "Municipal",
                    "FEDERAL" ~ "Federal",
                    "NAO DISPONIVEL" ~ NA
                ),
                tp_sinistro_primario = dplyr::case_match(
                    .data$tp_sinistro_primario,
                    "ATROPELAMENTO" ~ "Atropelamento",
                    "COLISAO" ~ "Colis\u00e3o",
                    "CHOQUE" ~ "Choque",
                    "OUTROS" ~ "Outros",
                    "NAO DISPONIVEL" ~ NA
                ),
                tipo_local = stringr::str_to_sentence(.data$tipo_local),
                tipo_local = dplyr::if_else(
                    .data$tipo_local == "Nao disponivel",
                    NA,
                    .data$tipo_local
                ),
                regiao_administrativa = stringr::str_to_sentence(
                    .data$regiao_administrativa
                ),
                dplyr::across(
                    .data$tp_sinistro_atropelamento:.data$tp_sinistro_nao_disponivel,
                    ~ dplyr::case_when(
                        .x == "S" ~ 1,
                        is.na(.x) ~ 0
                    )
                )
            ) |>
            dplyr::mutate(cod_ibge = as.character(.data$cod_ibge)) |>
            dplyr::left_join(list_ibge_sp, by = "cod_ibge") |>
            dplyr::select(
                .data$id_sinistro:.data$hora_sinistro,
                .data$nome_municipio,
                .data$dia_da_semana:.data$cod_ibge,
                .data$regiao_administrativa:.data$tp_sinistro_nao_disponivel
            )
    }
    if (file_type == "pessoas") {
        df <- df_infosiga |>
            dplyr::mutate(
                sexo = dplyr::case_match(
                    .data$sexo,
                    "MASCULINO" ~ "Masculino",
                    "FEMININO" ~ "Feminino",
                    "NAO DISPONIVEL" ~ NA
                ),
                data_obito = lubridate::dmy(.data$data_obito),
                tipo_de_vitima = dplyr::case_match(
                    .data$tipo_de_vitima,
                    "CONDUTOR" ~ "Condutor",
                    "PASSAGEIRO" ~ "Passageiro",
                    "PEDESTRE" ~ "Pedestre",
                    "NAO DISPONIVEL" ~ NA
                ),
                tipo_veiculo_vitima = dplyr::case_match(
                    .data$tipo_veiculo_vitima,
                    "MOTOCICLETA" ~ "Motocicleta",
                    "AUTOMOVEL" ~ "Autom\u00f3vel",
                    "NAO DISPONIVEL" ~ NA,
                    "OUTROS" ~ "Outros",
                    "BICICLETA" ~ "Bicicleta",
                    "CAMINHAO" ~ "Caminh\u00e3o",
                    "ONIBUS" ~ "\u00d4nibus",
                    .default = .data$tipo_veiculo_vitima
                ),
                # tipo_modo_vitima = dplyr::case_match(
                #     .data$tipo_veiculo_vitima,
                #     "A p\u00e9" ~ "Pedestre",
                #     "Motocicleta" ~ "Ocupante de motocicleta",
                #     "Autom\u00f3vel" ~ "Ocupante de autom\u00f3vel",
                #     "Bicicleta" ~ "Ciclista",
                #     "Caminh\u00e3o" ~ "Ocupante de caminh\u00e3o",
                #     "\u00d4nibus" ~ "Ocupante de \u00f4nibus",
                #     'Outros' ~ "Outros",
                #     .default = NA
                # ),
                gravidade_lesao = dplyr::case_match(
                    .data$gravidade_lesao,
                    "FATAL" ~ "Fatal",
                    "NAO DISPONIVEL" ~ NA,
                    "LEVE" ~ "Leve",
                    "GRAVE" ~ "Grave"
                ),
                faixa_etaria_demografica = dplyr::case_match(
                    .data$faixa_etaria_demografica,
                    "NAO DISPONIVEL" ~ NA,
                    "90 e +" ~ "90+",
                    .default = .data$faixa_etaria_demografica
                ),
                faixa_etaria_demografica = factor(
                    .data$faixa_etaria_demografica,
                    levels = c(
                        "00 a 04",
                        "05 a 09",
                        "10 a 14",
                        "15 a 19",
                        "20 a 24",
                        "25 a 29",
                        "30 a 34",
                        "35 a 39",
                        "40 a 44",
                        "45 a 49",
                        "50 a 54",
                        "55 a 59",
                        "60 a 64",
                        "65 a 69",
                        "70 a 74",
                        "75 a 79",
                        "80 a 84",
                        "85 a 89",
                        "90+"
                    )
                ),
                faixa_etaria_legal = dplyr::case_match(
                    .data$faixa_etaria_legal,
                    "NAO DISPONIVEL" ~ NA,
                    "80 ou mais" ~ "80+",
                    .default = .data$faixa_etaria_legal
                ),
                faixa_etaria_legal = factor(
                    .data$faixa_etaria_legal,
                    levels = c(
                        "0-17",
                        "18-24",
                        "25-29",
                        "30-34",
                        "35-39",
                        "40-44",
                        "45-49",
                        "50-54",
                        "55-59",
                        "60-64",
                        "65-69",
                        "70-74",
                        "75-79",
                        "80+"
                    )
                ),
                data_sinistro = lubridate::dmy(.data$data_sinistro),
                local_obito = dplyr::case_match(
                    .data$local_obito,
                    "PUBLICO" ~ "Publico",
                    "NAO DISPONIVEL" ~ NA,
                    "PRIVADO" ~ "Privado"
                )
            ) |>
            dplyr::select(
                .data$id_sinistro,
                .data$id_veiculo,
                .data$tipo_veiculo_vitima:.data$nacionalidade,
                .data$data_obito:.data$dia_obito,
                .data$local_obito,
                .data$tempo_sinistro_obito
            )
    }

    if (file_type == "veiculos") {
        df <- df_infosiga |>
            dplyr::select(
                .data$id_sinistro,
                .data$id_veiculo,
                .data$marca_modelo,
                .data$ano_fab,
                .data$ano_modelo,
                .data$cor_veiculo,
                .data$tipo_veiculo
            ) |>
            dplyr::mutate(
                tipo_veiculo = dplyr::case_match(
                    .data$tipo_veiculo,
                    "AUTOMOVEL" ~ "Autom\u00f3vel",
                    "MOTOCICLETA" ~ "Motocicleta",
                    "CAMINHAO" ~ "Caminh\u00e3o",
                    "ONIBUS" ~ "\u00d4nibus",
                    "OUTROS" ~ "Outros",
                    "BICICLETA" ~ "Bicicleta",
                    "NAO DISPONIVEL" ~ NA
                ),
                cor_veiculo = dplyr::if_else(
                    .data$cor_veiculo %in%
                        c("N\u00e3o Informado", "SEM IDENTIFICACAO"),
                    NA,
                    .data$cor_veiculo
                ),
                cor_veiculo = stringr::str_to_sentence(.data$cor_veiculo)
            )
    }
    return(df)
}
