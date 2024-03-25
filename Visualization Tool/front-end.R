# Libraries ----
source("back-end.R")

# Page ----
main_page <- function(data){
  
  fluidPage(
    
    setBackgroundColor(color = "#f0f0f0"),
    style = "@import url('https://fonts.googleapis.com/css2?family=Vidaloka&display=swap'); font-family: 'Vidaloka', serif;",
    
    fluidRow(
      style = "background-color: rgb(96, 96, 96); color: white; text-align: center",
      column(
        width = 12,
        allign = "center",
        tags$h2(
          "Data Visualization Hub"
        )
      )
    ),
    
    br(),
    
    div(
      style = "background-color: rgb(104, 115, 135); border-radius: 10px; padding: 2vh",
      tags$h3(
        "Last Readings",
        style = "text-align: center; color: white",
      ),
      div(
        style = "background-color: rgb(139, 148, 165); color: white; padding: 2vh; margin-bottom: 0.5vh",
        tags$h4(
          "By block"
        ),
        div(
          style = "background-color: rgb(136, 171, 184); padding: 0.5vh; color: black; text-align: center; width: 50%; margin: auto",
          radioButtons(
            inputId = "lastReadingRadio",
            label = "",
            inline = TRUE,
            choices = create_block_options(data),
          )
        ),
        br(),
        plotlyOutput(outputId = "lastReadingGraph"),
      ),
      div(
        style = "background-color: rgb(139, 148, 165); color: white; padding: 2vh; margin-top: 0.5vh",
        tags$h4(
          "Mean of blocks"
        ),
        fluidRow(
          uiOutput(outputId = "lastReadingCard"),
        ),
      )
    ),
    
    br(),
    
    div(
      style = "background-color: rgb(104, 115, 135); border-radius: 10px; color: white; padding: 2vh",
      tags$h3(
        "Temperature curves",
        style = "text-align: center",
      ),
      div(
        style = "background-color: rgb(139, 148, 165); color: white; padding: 2vh; margin-bottom: 0.5vh",
        tags$h4(
          "By block"
        ),
        div(
          style = "background-color: rgb(136, 171, 184); padding: 0.5vh; color: black; text-align: center; width: 50%; margin: auto",
          radioButtons(
            inputId = "tempCurvesBlockRadio",
            label = "",
            inline = TRUE,
            choices = create_block_options(data),
          )
        ),
        br(),
        plotlyOutput(outputId = "tempCurveBlock"),
        br(),
        div(
          style = "background-color: rgb(136, 171, 184); padding: 0.5vh; color: black; text-align: center; width: 25%; margin: auto; font-size: 16px",
          radioButtons(
            inputId = "tempCurvesTimeRadio",
            label = "",
            inline = TRUE,
            choices = c("Hour" = "hour",
                        "Day" = "day",
                        "Week" = "week",
                        "Month" = "month"),
          )
        ),
      ),
      div(
        style = "background-color: rgb(139, 148, 165); color: white; padding: 2vh; margin-top: 0.5vh",
        tags$h4(
          "Mean of blocks"
        ),
        br(),
        plotlyOutput(outputId = "tempCurveMeanBlock"),
        br(),
        div(
          style = "background-color: rgb(136, 171, 184); padding: 0.5vh; color: black; text-align: center; width: 25%; margin: auto; font-size: 16px",
          radioButtons(
            inputId = "tempCurvesMeanTimeRadio",
            label = "",
            inline = TRUE,
            choices = c("Hour" = "hour",
                        "Day" = "day",
                        "Week" = "week",
                        "Month" = "month"),
          )
        ),
      )
    ),
    
    br(),
    
    div(
      style = "background-color: rgb(104, 115, 135); border-radius: 10px; color: white; padding: 2vh",
      tags$h3(
        "Download the data",
        style = "text-align: center",
      ),
      fluidRow(
        column(
          align="center",
          width = 12,
          downloadButton(
            outputId = "downloadData",
            label = "Download",
            icon = icon("download"),
            style = "background-color: rgb(136, 171, 184);"
          )
        )
      )
    ),
    
    br(),
    
    div(
      style = "display: inline-block; text-align: center",
      tags$h5(
        "This tool was developed by the Ciampitti Lab Group"
      )
    )
    
  )
  
}

# Small functions ----
create_block_options <- function(data){
  choices <- unique(data$Group)
  named_list <- as.list(setNames(choices, choices))
  return(named_list)
}

