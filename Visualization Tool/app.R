# Libraries ----
library(shiny)
library(shinyWidgets)
source("back-end.R")
source("front-end.R")

# Data ----
data <- obtaining_data(file.source = "csv", file.path = "file.csv")

# UI ----
ui <- tagList(
  
  main_page(data)
  
)

# Server ----
server <- function(input, output, session) {
  
  output$lastReadingGraph <- renderPlotly({
    last_reading_graph(data = data,
                       group.selected = input$lastReadingRadio)
  })
  
  output$lastReadingCard <- renderUI({
    mean_card_blocks(data = data)
  })
  
  output$tempCurveBlock <- renderPlotly(
    curve_by_blocks(database = data,
                    group.selected = input$tempCurvesBlockRadio,
                    time.scale = input$tempCurvesTimeRadio)
  )
  
  output$tempCurveMeanBlock <- renderPlotly(
    curve_mean_blocks(database = data,
                      time.scale = input$tempCurvesMeanTimeRadio)
  )
  
  output$downloadData <- downloadHandler(
    filename = function(){
      paste0("dataVisualizationHub", Sys.Date(),".csv")
    },
    content = function(file){
      write.csv(data, file)
    }
  )
  
}

# App ----
shinyApp(ui, server)