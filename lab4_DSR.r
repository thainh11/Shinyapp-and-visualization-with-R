library(shiny)
library(leaflet)
library(jsonlite)
library(ggplot2)
library(tidyverse)
library(shinydashboard)
library(dplyr)
library(shinyMatrix)
library(plotly)

get_weather_info <- function(lat, lon) {
  api_key <- "e61767e7fe163757e69a41768aaffe05"
  API_call <-
    "https://api.openweathermap.org/data/2.5/weather?lat=%s&lon=%s&appid=%s"
  complete_url <- sprintf(API_call, lat, lon, api_key)
  json <- fromJSON(complete_url)
  
  location <- json$name
  temp <- json$main$temp - 273.2
  feels_like <- json$main$feels_like - 273.2
  humidity <- json$main$humidity
  weather_condition <- json$weather$description
  visibility <- json$visibility
  wind_speed <- json$wind$speed
  weather_info <- list(
    Location = location,
    Temperature = temp,
    Feels_like = feels_like,
    Humidity = humidity,
    WeatherCondition = weather_condition,
    Visibility = visibility,
    Wind_speed = wind_speed
  )
  return(weather_info)
}
get_forecast <- function(lat, lon) {
  api_key <- "35aa26b6f8b70e81d64047814f72a78a"
  
  API_call = "https://api.openweathermap.org/data/2.5/forecast?lat=%s&lon=%s&appid=%s"
  
  # Construct complete_url variable to store full url address
  complete_url = sprintf(API_call, lat, lon, api_key)
  #print(complete_url)
  json <- fromJSON(complete_url)
  
  df <- data.frame(
    Time = json$list$dt_txt,
    Location = json$city$name,
    feels_like = json$list$main$feels_like - 273.2,
    temp_min = json$list$main$temp_min - 273.2,
    temp_max = json$list$main$temp_max - 273.2,
    pressure = json$list$main$pressure,
    sea_level = json$list$main$sea_level,
    grnd_level = json$list$main$grnd_level,
    humidity = json$list$main$humidity,
    temp_kf = json$list$main$temp_kf,
    temp = json$list$main$temp - 273.2,
    id = sapply(json$list$weather, function(entry)
      entry$id),
    main = sapply(json$list$weather, function(entry)
      entry$main),
    icon = sapply(json$list$weather, function(entry)
      entry$icon),
    humidity = json$list$main$humidity,
    weather_conditions = sapply(json$list$weather, function(entry)
      entry$description),
    speed = json$list$wind$speed,
    deg = json$list$wind$deg,
    gust = json$list$wind$gust
  )
  
  return (df)
}

ui <- dashboardPage(
  dashboardHeader(title = "Interactive Map"),
  dashboardSidebar(sidebarMenu(
    menuItem("Weather", tabName = "weather", icon = icon("cloud")),
    menuItem("Forecast", tabName = "forecast", icon = icon("bolt"))
  )),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),
    tabItems(
      tabItem(
        tabName = "weather",
        fluidRow(
          box(width = 6, title = "Location", textOutput("location"), status = "primary"),
          box(width = 6, title = "Humidity", textOutput("humidity"), status = "info"),
          box(width = 6, title = "Temperature", textOutput("temperature"), status = "warning"),
          box(width = 6, title = "Feels Like", textOutput("feels_like"), status = "danger"),
          box(width = 6, title = "Weather Condition", textOutput("weather_condition"), status = "success"),
          box(width = 6, title = "Visibility", textOutput("visibility"), status = "primary"),
          box(width = 6, title = "Wind Speed", textOutput("wind_speed"), status = "info"),
          box(width = 12, title = "Map", leafletOutput("map"), class = 'map-container', status = "warning")
        )
      ),
      tabItem(
        tabName = "forecast",
        textOutput("location_"),
        selectInput(
          "feature",
          "Features:",
          list(
            "temp",
            "feels_like",
            "temp_min",
            "temp_max",
            "pressure",
            "sea_level",
            "grnd_level",
            "humidity",
            "speed",
            "deg",
            "gust"
        )
      ),
      #loadEChartsLibrary(),
      #tags$div(id = "test", style = "width:50%;height:400px;"),
      #deliverChart(div_id = "test")
      box(
        title = "Sample Line Chart",
        plotlyOutput("line_chart")
      )
    )
  )
  )
)

server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 105.8341598,
              lat = 21.0277644,
              zoom = 10)
  })
  
  output$map2 <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 105.8341598,
              lat = 21.0277644,
              zoom = 10)
  })
  
  click <- NULL
  weather_info <- NULL
  observeEvent(input$map_click, {
    click <<- input$map_click
    
    weather_info <<- get_weather_info(click$lat, click$lng)
    
    output$location <- renderText({
      paste(weather_info$Location)
    })
    
    output$humidity <- renderText({
      paste(weather_info$Humidity, "%")
    })
    
    output$temperature <- renderText({
      paste(weather_info$Temperature, "°C")
    })
    
    output$feels_like <- renderText({
      paste(weather_info$Feels_like, "°C")
    })
    
    output$weather_condition <- renderText({
      paste(weather_info$WeatherCondition)
    })
    
    output$visibility <- renderText({
      paste(weather_info$Visibility)
    })
    
    output$wind_speed <- renderText({
      paste(weather_info$Wind_speed)
    })
    
    
  })
  
  observeEvent(input$feature, {
    output$location_ <- renderText({
      paste('Location: ', weather_info$Location)
    })
    
    # set default
    default_lon = 105.8341598
    default_lat = 21.0277644
    data <- get_forecast(default_lat, default_lon)
    output$line_chart <- renderPlotly({
      feature_data <- data[, c("Time", input$feature)]
      plot_ly(data = feature_data, x = ~Time, y = ~.data[[input$feature]], type = 'scatter', mode = 'lines+markers', name = input$feature) %>%
        layout(title = "Sample Line Chart", xaxis = list(title = "Time"), yaxis = list(title = input$feature))
    })
    
    if (!is.null(click)) {
      data <- get_forecast(click$lat, click$lng)
      #dat <- data.frame(df[input$feature])
      #names(dat) <- c(input$feature)
      #row.names(dat) <- df$Time
      #renderLineChart(
      #  div_id = "test", 
      #  data = dat
      #)
      output$line_chart <- renderPlotly({
        feature_data <- data[, c("Time", input$feature)]
        plot_ly(data = feature_data, x = ~Time, y = ~.data[[input$feature]], type = 'scatter', mode = 'lines+markers', name = input$feature) %>%
          layout(title = "Sample Line Chart", xaxis = list(title = "Time"), yaxis = list(title = input$feature))
      })
    }
  })
}

shinyApp(ui, server)