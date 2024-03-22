# Libraries ----
library(xlsx)
library(httr)
library(jsonlite)
library(tidyverse)
library(tibble)
library(purrr)
library(lubridate)
library(ggplot2)
library(plotly)

# Obtaining data ----

obtaining_data <- function(file.source, file.path = NULL, GET.API = NULL){
  
  # CSV 
  if(file.source == "csv"){
    
    csv.data <- read.csv(file.path)
    
    database <- csv.data %>%
      mutate(Time = format(strptime(Time, format = '%H/%M', 'GMT'), '%H:%M'))
    
  }
  
  # XLSX
  if(file.source == "xlsx"){
    
    xlsx.data <- read.xlsx(file.path, sheetIndex = 1)
    
    database <- xlsx.data %>%
      mutate(Time = format(strptime(Time, format = '%H/%M', 'GMT'), '%H:%M'))
    
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
      mutate(Date = as.Date(Date, format = "%d/%m/%Y"),
             Time = format(strptime(Time, format = '%H/%M', 'GMT'), '%H:%M')) %>%
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

last_reading_graph <- function(data, group.selected){
  
  last.time <- tail(data$Time, n=1)
  
  lst.reading.data <- data %>%
    filter(Group == group.selected,
           Time == last.time)
  
  num.breaks <- nrow(lst.reading.data)
  
  graph <- ggplot(data = lst.reading.data,
                  aes(x = Device, y = Reading)) + 
    geom_bar(stat = "identity",
             fill=rgb(0.376,0.376,0.376)) +
    scale_x_continuous(breaks = seq(0, num.breaks, 1)) +
    theme_minimal()
  
  ggplotly(graph)
  
}

#last_reading_graph(data = data, group.selected = "1")

## Curves ----

### By blocks ----

curve.by.blocks <- function(data, group.selected, time.scale){
  
  data$Time <- as.POSIXct(data$Time, format = "%H:%M")
  data$Date <- as.Date(data$Date)
  
  if(time.scale == "minute"){
    curve.data <- data %>%
      filter(Group == group.selected) %>%
      group_by(Date,
               Hour = hour(Time),
               Minute = minute(Time)) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Minute, y = Readings, group=1))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "hour"){
    curve.data <- data %>%
      filter(Group == group.selected) %>%
      group_by(Date,
               Hour = hour(Time)) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Hour, y = Readings, group=1))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "day"){
    curve.data <- data %>%
      filter(Group == group.selected) %>%
      group_by(Date) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Date, y = Readings, group=1))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "week"){
    curve.data <- data %>%
      filter(Group == group.selected) %>%
      group_by(Week = format(Date, "%Y-%U") ) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Week, y = Readings, group=1))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "month"){
    curve.data <- data %>%
      filter(Group == group.selected) %>%
      group_by(Month = format(Date, "%Y-%m")) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Month, y = Readings, group=1))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  
  ggplotly(graph)
  
}

#curve.by.blocks(data = data, group.selected = "1", time.scale = "mintue")

### Mean of blocks ----

curve.mean.blocks <- function(data, time.scale){
  
  data$Time <- as.POSIXct(data$Time, format = "%H:%M")
  data$Date <- as.Date(data$Date)
  
  if(time.scale == "minute"){
    curve.data <- data %>%
      group_by(Group,
               Date,
               Hour = hour(Time),
               Minute = minute(Time)) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Minute, y = Readings, color=Group))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "hour"){
    curve.data <- data %>%
      group_by(Group,
               Date,
               Hour = hour(Time)) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Hour, y = Readings, color=Group))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "day"){
    curve.data <- data %>%
      group_by(Group, Date) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Date, y = Readings, color=Group))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "week"){
      group_by(Group,
               Week = format(Date, "%Y-%U") ) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Week, y = Readings, color=Group))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  if(time.scale == "month"){
    curve.data <- data %>%
      group_by(Group,
               Month = format(Date, "%Y-%m")) %>%
      summarise(Readings = mean(Reading, na.rm = TRUE))
    
    graph <- ggplot(data = curve.data,
                    aes(x = Month, y = Readings, color=Group))+
      geom_line()+
      geom_point()+
      theme_minimal()
  }
  
  ggplotly(graph)
}

#curve.mean.blocks(data = data, time.scale = "minute")
