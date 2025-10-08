
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


df_sinistros <- load_infosiga(
  file_type = "sinistros", 
  zip_path = "data-raw/dados_infosiga.zip"
)
#> ℹ Using "','" as decimal and "'.'" as grouping mark. Use `read_delim()` for more control.
#> Rows: 1257986 Columns: 48
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ";"
#> chr  (28): tipo_registro, data_sinistro, mes_sinistro, dia_sinistro, ano_mes...
#> dbl  (17): id_sinistro, ano_sinistro, latitude, longitude, cod_ibge, qtd_ped...
#> lgl   (2): qtd_gravidade_ileso, tp_sinistro_colisao_traseira
#> time  (1): hora_sinistro
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

df_sinistros_clean <- clean_infosiga(df_sinistros, "sinistros")

head(df_sinistros_clean)
#> # A tibble: 6 × 47
#>   id_sinistro tipo_registro data_sinistro ano_sinistro mes_sinistro dia_sinistro
#>         <dbl> <chr>         <date>               <dbl> <chr>        <chr>       
#> 1     2501575 Sinistro fat… 2014-12-21            2014 12           21          
#> 2     2456933 Sinistro fat… 2014-12-23            2014 12           23          
#> 3     2463759 Sinistro fat… 2014-12-26            2014 12           26          
#> 4     2487781 Sinistro fat… 2014-12-28            2014 12           28          
#> 5     2489730 Sinistro fat… 2014-12-28            2014 12           28          
#> 6     2462674 Sinistro fat… 2014-12-31            2014 12           31          
#> # ℹ 41 more variables: hora_sinistro <time>, nome_municipio <chr>,
#> #   dia_da_semana <chr>, turno <chr>, logradouro <chr>,
#> #   numero_logradouro <dbl>, tipo_via <chr>, tipo_local <chr>, latitude <dbl>,
#> #   longitude <dbl>, cod_ibge <chr>, regiao_administrativa <chr>,
#> #   administracao <chr>, conservacao <chr>, circunscricao <chr>,
#> #   tp_sinistro_primario <chr>, qtd_pedestre <dbl>, qtd_bicicleta <dbl>,
#> #   qtd_motocicleta <dbl>, qtd_automovel <dbl>, qtd_onibus <dbl>, …
```

## License

This package is licensed under the GPL (\>= 3) license.

## Citation

``` r
citation("ost.utils")
#> To cite package 'ost.utils' in publications use:
#> 
#>   Santos PAB (2025). _ost.utils: Provides Utility Methods and Tools for
#>   COST_. R package version 0.1.3,
#>   https://pedrobsantos21.github.io/ost.utils/,
#>   <https://github.com/pedrobsantos21/ost.utils>.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {ost.utils: Provides Utility Methods and Tools for COST},
#>     author = {Pedro Augusto Borges Santos},
#>     year = {2025},
#>     note = {R package version 0.1.3, https://pedrobsantos21.github.io/ost.utils/},
#>     url = {https://github.com/pedrobsantos21/ost.utils},
#>   }
```
