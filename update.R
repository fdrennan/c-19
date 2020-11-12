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
  select(-contains('total'))


con <- postgres_connector()
if (TRUE) {
  if (dbExistsTable(conn = con, name = 'covid')) {
    dbRemoveTable(conn = con, name = 'covid')
  }
  dbCreateTable(conn = con, name = 'covid', fields = covid)
}

covid %>% 
  split(.$location) %>% 
  walk(function(x) {
    glimpse(x)
    dbWriteTable(conn = con, name = 'covid', value = x, append=TRUE)
  })


