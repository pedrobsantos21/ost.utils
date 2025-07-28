#' Download and Extract Infosiga data
#'
#' @description
#' Downloads the complete Infosiga.SP database from the official website,
#' handles potential HTTP errors with retries, and extracts the contents
#' of the resulting ZIP file to a specified directory.
#'
#' @details
#' The function performs the download to a temporary file and then unzips it.
#' It uses a robust `httr2` request that forces HTTP/1.1, sets a common
#' User-Agent, and automatically retries the download up to 3 times in case of
#' transient network errors. A progress bar is displayed during the download.
#'
#' @param destpath A string specifying the directory path where the data
#'   files should be extracted. The path will be normalized, and if it's a
#'   relative path, it will be resolved from the current working directory.
#'
#' @return
#' This function does not return a value. It is called for its side effects:
#' downloading a file and extracting it to the `destpath`.
#'
#' @export
#' @import httr2
#' @import cli
#' @import fs
#' @import utils
#' @import glue
#'
#' @examples
#' \dontrun{
#' # Create a temporary directory to store the data
#' temp_dir <- tempdir()
#'
#' # Download and extract the data
#' download_infosiga(destpath = temp_dir)
#' }
download_infosiga <- function(destpath) {
    zip_url <- "https://infosiga.detran.sp.gov.br/rest/painel/download/4"
    tempzip <- tempfile()

    # pb <- progress::progress_bar$new(
    #     format = "Downloading [:bar] :percent in :elapsed | ETA: :eta | :rate",
    #     total = NA,
    #     witdh = 80,
    #     clear = FALSE
    # )

    cli::cli_alert_info("Starting download...")

    infosiga_req <- httr2::request(zip_url) |>
        httr2::req_options(http_version = 2) |>
        httr2::req_user_agent(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
        ) |>
        httr2::req_retry(max_tries = 3) |>
        httr2::req_progress() |>
        httr2::req_error(is_error = \(resp) httr2::resp_status(resp) != 200)

    tryCatch(
        {
            resp <- infosiga_req |>
                httr2::req_perform(path = tempzip)
            cli::cli_alert_success("Download completed.")
        },
        error = function(e) {
            cli::cli_abort("Download failed.")
            if (!is.null(e$parent)) {
                print(e$parent$message)
            } else {
                print(e$message)
            }
        }
    )

    cli::cli_alert_info("Extrating zip...")
    utils::unzip(tempzip, exdir = fs::path_abs(destpath))
    cli::cli_alert_success(glue::glue(
        "Data extracted successfully at '{fs::path_abs(destpath)}'"
    ))

    on.exit(unlink(tempzip))
}

#' Load Infosiga Data from Local Files
#'
#' @description
#' Reads and combines one or more Infosiga data files (CSV) of a specific
#' type from a given directory into a single data frame.
#'
#' @details
#' This function searches for all files in the specified `path` that start with
#' the `file_type` prefix (e.g., `sinistros_2023.csv`). It then uses
#' `readr::read_csv2` to parse these semicolon-separated files. The function
#' assumes 'latin1' encoding, which is necessary for handling special
#' characters in the original data. All found files of the same type are
#' stacked into a single tibble.
#'
#' @param file_type A string specifying the type of data to load. Must be one
#'   of `'sinistros'` (the default), `'pessoas'`, or `'veiculos'`.
#' @param path A string specifying the path to the directory containing the
#'   Infosiga CSV files.
#'
#' @return A `tibble` (data frame) containing the combined data from all
#'   matching CSV files.
#'
#' @export
#' @importFrom readr read_csv2 locale
#' @import rlang
#'
#' @examples
#' \dontrun{
#' # First, download the data
#' data_dir <- tempdir()
#' download_infosiga(destpath = data_dir)
#'
#' # Now, load the 'sinistros' data
#' df_sinistros <- load_infosiga(file_type = "sinistros", path = data_dir)
#'
#' # Load the 'pessoas' data
#' df_pessoas <- load_infosiga(file_type = "pessoas", path = data_dir)
#' }
load_infosiga <- function(
    file_type = c("sinistros", "pessoas", "veiculos"),
    path
) {
    if (fs::dir_exists(glue::glue("{path}/dados_infosiga"))) {
        path <- fs::path(path, "dados_infosiga")
    }

    files <- list.files(
        path,
        pattern = glue::glue("^{file_type}"),
        full.names = TRUE
    )

    df <- readr::read_csv2(files, locale = readr::locale(encoding = "latin1"))
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
                numero_logradouro = as.numeric(.data$numero_logradouro),
                tipo_via = dplyr::case_match(
                    .data$tipo_via,
                    "NAO DISPONIVEL" ~ NA,
                    c(
                        "RODOVIAS",
                        "RURAL",
                        "RURAL (COM CARACTER\u00cdSTICA DE URBANA)"
                    ) ~
                        "Estradas e rodovias",
                    c("URBANA", "VIAS MUNICIPAIS") ~ "Vias urbanas"
                ),
                dplyr::across(
                    dplyr::starts_with("tp_veiculo"),
                    ~ dplyr::if_else(is.na(.x), 0, .x)
                ),
                dplyr::across(
                    dplyr::starts_with("gravidade"),
                    ~ dplyr::if_else(is.na(.x), 0, .x)
                ),
                administracao_via = dplyr::case_match(
                    .data$administracao,
                    c(
                        "CONCESSION\u00c1RIA",
                        "CONCESSION\u00c1RIA-ANTT",
                        "CONCESSION\u00c1RIA-ARTESP"
                    ) ~
                        "Concession\u00e1ria",
                    "NAO DISPONIVEL" ~ NA,
                    "PREFEITURA" ~ "Prefeitura",
                    .default = .data$administracao
                ),
                jurisdicao_via = dplyr::case_match(
                    .data$jurisdicao,
                    "ESTADUAL" ~ "Estadual",
                    "MUNICIPAL" ~ "Municipal",
                    "FEDERAL" ~ "Federal",
                    "NAO DISPONIVEL" ~ NA
                ),
                tipo_sinistro_primario = dplyr::case_match(
                    .data$tipo_acidente_primario,
                    "ATROPELAMENTO" ~ "Atropelamento",
                    "COLISAO" ~ "Colis\u00e3o",
                    "CHOQUE" ~ "Choque",
                    "NAO DISPONIVEL" ~ NA
                ),
                dplyr::across(
                    dplyr::starts_with("tp_sinistro"),
                    ~ dplyr::case_when(
                        .x == "S" ~ 1,
                        is.na(.x) ~ 0
                    )
                )
            ) |>
            dplyr::left_join(
                y = municipios,
                by = c("municipio" = "s_ds_municipio")
            ) |>
            dplyr::mutate(cod_ibge = as.character(.data$cod_ibge)) |>
            dplyr::left_join(list_ibge_sp, by = "cod_ibge") |>
            dplyr::select(
                .data$id_sinistro,
                .data$data_sinistro,
                .data$hora_sinistro,
                .data$cod_ibge,
                .data$regiao_administrativa,
                .data$nome_municipio,
                .data$logradouro,
                .data$numero_logradouro,
                .data$tipo_via,
                .data$longitude,
                .data$latitude,
                dplyr::starts_with("tp_veic"),
                .data$tipo_registro,
                dplyr::starts_with("gravidade"),
                .data$administracao_via,
                .data$conservacao,
                .data$jurisdicao_via,
                .data$tipo_sinistro_primario,
                dplyr::starts_with("tp_sinistro")
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
                    .data[["tipo_de v\u00edtima"]],
                    "CONDUTOR" ~ "Condutor",
                    "PASSAGEIRO" ~ "Passageiro",
                    "PEDESTRE" ~ "Pedestre",
                    "NAO DISPONIVEL" ~ NA
                ),
                tipo_veiculo_vitima = dplyr::case_match(
                    .data$tipo_veiculo_vitima,
                    c("PEDESTRE", "Pedestre") ~ "A p\u00e9",
                    "MOTOCICLETA" ~ "Motocicleta",
                    "AUTOMOVEL" ~ "Autom\u00f3vel",
                    "NAO DISPONIVEL" ~ NA,
                    "OUTROS" ~ "Outros",
                    "BICICLETA" ~ "Bicicleta",
                    "CAMINHAO" ~ "Caminh\u00e3o",
                    "ONIBUS" ~ "\u00d4nibus",
                    .default = .data$tipo_veiculo_vitima
                ),
                tipo_modo_vitima = dplyr::case_match(
                    .data$tipo_veiculo_vitima,
                    "A p\u00e9" ~ "Pedestre",
                    "Motocicleta" ~ "Ocupante de motocicleta",
                    "Autom\u00f3vel" ~ "Ocupante de autom\u00f3vel",
                    "Bicicleta" ~ "Ciclista",
                    "Caminh\u00e3o" ~ "Ocupante de caminh\u00e3o",
                    "\u00d4nibus" ~ "Ocupante de \u00f4nibus",
                    'Outros' ~ "Outros",
                    .default = NA
                ),
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
                data_sinistro = lubridate::dmy(.data$data_sinistro)
            ) |>
            dplyr::rename(
                tipo_vitima = .data$`tipo_de_vitima`
            ) |>
            dplyr::select(
                .data$id_sinistro,
                .data$data_sinistro,
                .data$data_obito,
                .data$sexo,
                .data$idade,
                .data$tipo_vitima,
                .data$faixa_etaria_demografica,
                .data$faixa_etaria_legal,
                .data$tipo_veiculo_vitima,
                .data$tipo_modo_vitima,
                .data$gravidade_lesao
            )
    }

    if (file_type == "veiculos") {
        df <- df_infosiga |>
            dplyr::select(
                .data$id_sinistro,
                ano_fabricacao = .data$ano_fab,
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
                )
            )
    }
    return(df)
}
