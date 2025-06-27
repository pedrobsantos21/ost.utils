
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ost.utils

<!-- badges: start -->

[![R-CMD-check](https://github.com/pedrobsantos21/ost.utils/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pedrobsantos21/ost.utils/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The `ost.utils` package provides utility methods and tools to ease the
workflow in projects developed by Coordenadoria do Observatório de
Segurança no Trânsito (COST) of Detran-SP.

## Installation

You can install the `ost.utils` from GitHub with:

``` r
# install.packages("pak")
pak::pak("pedrobsantos21/ost.utils")
```

## Example

This is a basic example which shows you how to download and clean
Infosiga.SP data:

``` r
library(ost.utils)

temp <- tempdir()
download_infosiga(temp)
#> ℹ Starting download...
#> ✔ Download completed.
#> ℹ Extrating zip...
#> ✔ Data extracted successfully at '/tmp/RtmpqOX4rj'
df_sinistros <- load_infosiga(file_type = "sinistros", path = temp)
#> ℹ Using "','" as decimal and "'.'" as grouping mark. Use `read_delim()` for more control.
#> Rows: 1208097 Columns: 43
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ";"
#> chr  (26): tipo_registro, data_sinistro, mes_sinistro, dia_sinistro, ano_mes...
#> dbl  (15): id_sinistro, ano_sinistro, latitude, longitude, tp_veiculo_bicicl...
#> lgl   (1): gravidade_ileso
#> time  (1): hora_sinistro
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
df_sinistros_clean <- clean_infosiga(df_sinistros, "sinistros")

head(df_sinistros_clean)
#> # A tibble: 6 × 40
#>   id_sinistro data_sinistro hora_sinistro cod_ibge regiao_administrativa     
#>         <dbl> <date>        <time>        <chr>    <chr>                     
#> 1     2501575 2014-12-21    20:00         3509502  Campinas                  
#> 2     2456933 2014-12-23       NA         3505500  Barretos                  
#> 3     2463759 2014-12-26    06:52         3550308  Metropolitana de São Paulo
#> 4     2487781 2014-12-28    14:30         3510609  Metropolitana de São Paulo
#> 5     2489730 2014-12-28       NA         3541000  Baixada Santista          
#> 6     2462674 2014-12-31    22:53         3550308  Metropolitana de São Paulo
#> # ℹ 35 more variables: nome_municipio <chr>, logradouro <chr>,
#> #   numero_logradouro <dbl>, tipo_via <chr>, longitude <dbl>, latitude <dbl>,
#> #   tp_veiculo_bicicleta <dbl>, tp_veiculo_caminhao <dbl>,
#> #   tp_veiculo_motocicleta <dbl>, tp_veiculo_nao_disponivel <dbl>,
#> #   tp_veiculo_onibus <dbl>, tp_veiculo_outros <dbl>,
#> #   tp_veiculo_automovel <dbl>, tipo_registro <chr>,
#> #   gravidade_nao_disponivel <dbl>, gravidade_leve <dbl>, …
```

## License

This package is licensed under the GPL (\>= 3) license.

## Citation

``` r
citation("ost.utils")
#> To cite package 'ost.utils' in publications use:
#> 
#>   Santos PAB (2025). _ost.utils: Provides Utility Methods and Tools for
#>   COST_. R package version 0.0.0.9000,
#>   <https://github.com/pedrobsantos21/ost.utils>.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {ost.utils: Provides Utility Methods and Tools for COST},
#>     author = {Pedro Augusto Borges Santos},
#>     year = {2025},
#>     note = {R package version 0.0.0.9000},
#>     url = {https://github.com/pedrobsantos21/ost.utils},
#>   }
```
