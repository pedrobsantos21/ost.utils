path_list_ibge = "data-raw/RELATORIO_DTB_BRASIL_MUNICIPIO.xls"
list_ibge = readxl::read_excel(path_list_ibge, skip = 6)

list_ibge_sp = list_ibge |>
    janitor::clean_names() |>
    dplyr::filter(nome_uf == "São Paulo") |>
    dplyr::select(cod_ibge = codigo_municipio_completo, nome_municipio)

save(list_ibge_sp, "../R/sysdata.rda")
