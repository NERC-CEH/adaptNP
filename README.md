# adaptNP: adaptive sampling methods for high frequency envrionmental sensors

<!-- badges: start -->
# [![R-CMD-check](https://github.com/NERC-CEH/jsdmstan/workflows/R-CMD-check/badge.svg)](https://github.com/NERC-CEH/adaptNP/actions)
<!-- # [![Codecov test coverage](https://codecov.io/gh/NERC-CEH/jsdmstan/branch/main/graph/badge.svg)](https://codecov.io/gh/NERC-CEH/jsdmstan?branch=main) -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<!-- badges: end -->

> Under initial development. Not working yet.

This is an R package for running adaptive sampling methods for high frequency environmental sensors.

This package can flag data for (very) high frequency sampling based on different criteria.

## Installation

This package can be installed using the [remotes](https://remotes.r-lib.org/index.html) package using the following code:

```
# install.packages("remotes")
remotes::install_github("NERC-CEH/adaptNP")
```


## Using adaptNP

Example code:

```
library(adaptNP)
library(dplyr)  # recommended for the examples
```

Get data:
```

```

Flag data (1. given criteria in data):
```
criteria = '(Sonde1_Temperature > 15) | (Sonde1_pH >7)'
flag_event(sonde_data,criteria)
```

Flag data (2. clustering and other data driven methods):
```

```

Extract periods of events (given minimum segment length):
```
extract_event_periods(
  sonde_data %>% 
    rename(timestamp=TIMESTAMP,flag=event_flag),
  min_length=50)
```

Down-sample data (from 2 minutes, e.g. 15 minutes, 2 days)
Note in python, this can be done using the `resample` function in `pandas`.
```
sonde_data_15min <- sonde_data %>% 
    mutate(TIMESTAMP = floor_date(TIMESTAMP, "15 minutes")) %>%
    group_by(TIMESTAMP) %>%
    summarise(across(everything(), first), .groups='drop')
    
sonde_data_2d <- sonde_data %>% 
    mutate(TIMESTAMP = floor_date(TIMESTAMP, "2 days")) %>%
    group_by(TIMESTAMP) %>%
    summarise(across(everything(), first), .groups='drop')   
```


Rolling average smoothing (across all columns)
```
sonde_data_rollmean <- sonde_data %>% dplyr::select(-RECORD) %>% 
    mutate(across(everything(), ~ rollapply(.x, width = 7, FUN = mean, fill = NA, align = "center"))) %>% 
    drop_na(TIMESTAMP)
```


## Developer guide

`usethis::use_pkgdown()`

`devtools::document()`

To build reference, run `pkgdown::build_reference()`.

To preview `pkgdown` site, run ` pkgdown::preview_site(path='reference/index.html')`.

***
## Acknowledgment


This work was funded by the Natural Environment Research Council (part of UK Research and Innovation) under the Innovative Environmental Monitoring programme: Adaptive multi-nutrient monitoring system (ADAPT-NP)  (Grant Reference NE/Z503551/1).

[<img src="https://edshare.soton.ac.uk/21748/4.haspreviewThumbnailVersion/university-of-southampton-text.png" width="250"/>](https://edshare.soton.ac.uk/21748/4.haspreviewThumbnailVersion/university-of-southampton-text.png)
[<img src="https://raw.githubusercontent.com/NERC-CEH/jsdmstan/refs/heads/main/man/figures/UKCEH-Logo.png" width="250"/>](https://ceh.ac.uk)
"# adaptNP" 
