library(surveydown)

# Database connection (set to ignore for testing)
# To use a real database, run: sd_db_config() first
db <- sd_db_connect()

# Main UI
ui <- sd_ui()

server <- function(input, output, session) {
  # Generate completion code
  completion_code <- sd_completion_code(8)
  sd_store_value(completion_code)

  # Hide director question
  sd_show_if(
    FALSE ~ 'favorite_director'
  )

  # Main server
  sd_server(db = db)
}

shiny::shinyApp(ui = ui, server = server)
