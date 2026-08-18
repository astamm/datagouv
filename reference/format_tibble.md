# Parse a resource into a tidy tibble

Converts a data frame (e.g. read with `readr`) into a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
and, optionally, drops all rows that contain at least one missing value.

## Usage

``` r
format_tibble(x, remove_na = FALSE)
```

## Arguments

- x:

  A data frame or tibble to convert.

- remove_na:

  Whether to drop rows containing any `NA` value. Defaults to `FALSE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html).

## Examples

``` r
df <- data.frame(a = c(1, 2, NA), b = c("x", NA, "z"))
format_tibble(df)
#> # A tibble: 3 × 2
#>       a b    
#>   <dbl> <chr>
#> 1     1 x    
#> 2     2 NA   
#> 3    NA z    
format_tibble(df, remove_na = TRUE)
#> # A tibble: 1 × 2
#>       a b    
#>   <dbl> <chr>
#> 1     1 x    
```
