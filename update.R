library(fs)
library(readr)
library(dplyr)
library(skimr)

remote_path <- 'https://github.com/fdrennan/covid-19-data/raw/master/public/data/owid-covid-data.csv'
local_path <- 'covid-19.csv'

if(!file_exists(local_path)) {
  download.file(remote_path, local_path)
}

covid <-
  read_csv(local_path)

covid <-
  covid %>%
  select(-contains('total'))

glimpse(covid)

covid_locations <-
  covid %>%
  group_by(continent, location) %>%
  count()


usethis::use_data(covid_locations, overwrite = TRUE)
