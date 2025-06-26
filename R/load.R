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

load_infosiga <- function(file_type, path) {}

clean_infosiga <- function(df_infosiga, type) {}
