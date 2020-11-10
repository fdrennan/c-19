library(glue)
library(fs)
library(readr)
library(dplyr)
library(skimr)
library(stringr)
library(DBI)
library(covid)
library(dbx)
library(purrr)

remote_path <- 'https://github.com/fdrennan/covid-19-data/raw/master/public/data/owid-covid-data.csv'
local_path <- 'covid-19.csv'

if(file_exists(local_path)) {
  fs::file_delete(local_path)
}

download.file(remote_path, local_path)

covid <- read_csv(local_path)

covid <-
  covid %>%
  select(-contains('total')) %>% 
  mutate(id = paste0(continent, ' - ', location))


con <- postgres_connector()

if (TRUE) {
  if (dbExistsTable(conn = con, name = 'covid')) {
    message('Deleting covid table')
    dbRemoveTable(conn = con, name = 'covid')
  }
  dbCreateTable(conn = con, name = 'covid', fields = head(covid, 1000)) 
}


covid_split <- split(
  covid, paste0(covid$continent, covid$location)
) 
  
walk(
  covid_split,
  function(x) {
    continent <- unique(x$continent)
    location <- unique(x$location)
    message(glue('Uploading {continent} {location}'))
    dbAppendTable(conn = con, name = 'covid', value = x, append=TRUE)
})

