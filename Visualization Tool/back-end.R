# Libraries ----
#library(xlsx)
library(httr)
library(jsonlite)
library(tidyverse)
library(tibble)
library(purrr)
library(lubridate)
library(ggplot2)
library(plotly)
library(shinydashboard)

# Obtaining data ----

obtaining_data <- function(file.source, file.path = NULL, GET.API = NULL){
  
  # CSV 
  if(file.source == "csv"){
    
    csv.data <- read.csv(file.path)
    
    database <- csv.data %>%
      mutate(DateTime = as.POSIXct(strptime(DateTime, format = "%d/%m/%Y %H/%M")))
    
  }
  
  # XLSX
  if(file.source == "xlsx"){
    
    xlsx.data <- read.xlsx(file.path, sheetIndex = 1)
    
    database <- xlsx.data %>%
      mutate(DateTime = as.POSIXct(strptime(DateTime, format = "%d/%m/%Y %H/%M")))
    
  }
  
  # NoSQL
  if(file.source == "NoSQL"){
    
    response <- GET(GET.API)
    
    json <- content(response, as = "text") %>% 
      fromJSON() %>%
      select(-c(`LoRa RSSI`, `Wifi RSSI`, `_id`))
    
    tibble_data <- as_tibble(json)
    
    num_repeats <- ncol(tibble_data$reading)
    
    repeated_tibble <- tibble_data %>%
      select(-c(reading)) %>%
      rename(Date = date, Group = group, Time = hour) %>%
      mutate(DateTime = as.POSIXct(strptime(DateTime, format = "%d/%m/%Y %H/%M"))) %>%
      slice(rep(row_number(), each = num_repeats))
    
    readings <- as_tibble(tibble_data$reading, .name_repair="universal")
    
    readings <- readings %>%
      pivot_longer(cols = everything(), names_to = "Device", values_to = "Reading")
    
    readings$Device <- gsub("^\\.\\.\\.", "", readings$Device)
    
    database <- bind_cols(repeated_tibble, readings)
    database$Reading <- as.numeric(database$Reading)
    database$Device <- as.numeric(database$Device)
    
  }
  
  return(database)
  
}

#data <- obtaining_data(file.source = "csv", file.path = "file.csv")
#data <- obtaining_data(file.source = "NoSQL", GET.API = "http://127.0.0.1:5000/obtain")

# Generating graphics -----
## Last Readings ----

### Bar graph ----
last_reading_graph <- function(data, group.selected){
  
  last.time <- tail(data$DateTime, n=1)
  
  lst.reading.data <- data %>%
    filter(Group == group.selected,
           DateTime == last.time)
  
  num.breaks <- nrow(lst.reading.data)
  
  graph <- ggplot(data = lst.reading.data,
                  aes(x = Device, y = Reading)) + 
    geom_bar(stat = "identity",
             fill=rgb(0.376,0.376,0.376)) +
    scale_x_continuous(breaks = seq(0, num.breaks, 1)) +
    ylab("Temperature °C")+
    theme_minimal()
  
  ggplotly(graph)
  
}

#last_reading_graph(data = data, group.selected = "1")

### Cards ----
mean_card_blocks <- function(data){
  
  last.time <- tail(data$DateTime, n=1)
  
  lst.reading.data <- data %>%
    filter(DateTime == last.time) %>%
    group_by(Group) %>%
    summarise(Value = mean(Reading))
  
  choices <- unique(data$Group)
  
  
  lapply(choices, function(choice){
    
    div(
      style = "background-color: rgb(136, 171, 184); color: black; padding: 0.3vh; width: 10%; margin: 1vh",
      tags$h3(
        style = "text-align: center",
        str_glue(round(lst.reading.data$Value[lst.reading.data$Group==choice], 1), " °C")
      ),
      tags$h5(
        style = "text-align: end; margin-right: 10%",
        str_glue("Block ", choice)
      )
    )
    
  })
    
}


## Temperature Curves ----

### By blocks ----

curve_by_blocks <- function(database, group.selected, time.scale){
  
  database$Device <- as.factor(database$Device)
  
  if(time.scale == "hour"){
    curve.data <- database %>%
      filter(Group == group.selected) %>%
      group_by(DateTime)
    
    graph <- ggplot(data = curve.data,
                    aes(x = DateTime, y = Reading, color = Device))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  if(time.scale == "day"){
    curve.data <- database %>%
      filter(Group == group.selected) %>%
      group_by(Date = format(DateTime, "%Y-%m-%d"))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Date, y = Reading, color = Device))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  if(time.scale == "week"){
    curve.data <- database %>%
      filter(Group == group.selected) %>%
      group_by(Week = format(DateTime, "%Y-%U") )
    
    graph <- ggplot(data = curve.data,
                    aes(x = Week, y = Reading, color = Device))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  if(time.scale == "month"){
    curve.data <- database %>%
      filter(Group == group.selected) %>%
      group_by(Month = format(DateTime, "%Y-%m"))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Month, y = Reading, color = Device))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  
  ggplotly(graph)
  
}

#curve.by.blocks(database = data, group.selected = "1", time.scale = "minute")

### Mean of blocks ----

curve_mean_blocks <- function(database, time.scale){
  
  database$Group <- as.factor(database$Group)
  
  if(time.scale == "hour"){
    curve.data <- database %>%
      group_by(Group,
               DateTime) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = DateTime, y = Readings, color=Group))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  if(time.scale == "day"){
    curve.data <- database %>%
      group_by(Group,
               Date = format(DateTime, "%Y-%m-%d")) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Date, y = Readings, group=Group))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  if(time.scale == "week"){
    curve.data <- database %>%  
      group_by(Group,
               Week = format(DateTime, "%Y-%U") ) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Week, y = Readings, group=Group))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  if(time.scale == "month"){
    curve.data <- database %>%
      group_by(Group,
               Month = format(DateTime, "%Y-%m")) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Month, y = Readings, group=1))+
      geom_line()+
      geom_point()+
      ylab("Temperature °C")+
      theme_minimal()
  }
  
  ggplotly(graph)
}

#curve.mean.blocks(database = data, time.scale = "minute")
