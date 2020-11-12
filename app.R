## app.R ##
library(shinydashboard)
library(covid)
library(RPostgres)
library(dbplyr)
library(glue)
library(dbplyr)
library(dplyr)
library(ggplot2)
library(tidyr)


grab_meta <- function() {
  con <- postgres_connector()
  on.exit({
    message('Disconnecting from Postgres')
    dbDisconnect(conn = con)
  })
  covid <- collect(tbl(con, in_schema('public', 'covid')))
}


covid_data <- grab_meta()
location <- sort(unique(covid_data$location))
column_option <- colnames(covid_data)[!colnames(covid_data) %in% c('iso_code', 'continent', 'location', 'date')]


ui <- dashboardPage(
  dashboardHeader(title = "Basic dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Widgets", tabName = "widgets", icon = icon("th"))
    )
  ),
  dashboardBody(
    selectizeInput(inputId = 'location', 'Location', location, selected = location[[1]]),
    selectizeInput(inputId = 'column_option', 'Type', column_option, selected = column_option[[1]]),
    tabItems(
      # First tab content
      tabItem(tabName = "dashboard",
              fluidRow(
                box(plotOutput("death_plot", height = 250))
              )
      )
    )
  )
)

server <- function(input, output) {

  output$death_plot <- renderPlot({

    get_covid <- function(
      query_id = NULL, 
      from = Sys.Date() - 60, 
      to = Sys.Date()
    ) {
      con <- postgres_connector()
      
      covid_data <- 
        tbl(con, in_schema('public', 'covid')) %>% 
        filter(location == query_id,
               between(date, local(from), (to)))
  
      
      collect(covid_data)
    }
    
    covid_data <- get_covid(query_id = input$location)
  
    plot_data <- select(covid_data, date, location, input$column_option) 
    
    ggplot(plot_data) +
      aes_string(x = 'date', y = input$column_option) +
      geom_col() +
      facet_wrap(location ~ ., scales = 'free') +
      ggtitle(label = glue('Plot of {input$location}')) 
    
  })
}

shinyApp(ui, server)