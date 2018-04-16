#' MakePlot
#' 
#' @export
#' @param mydata some object or dataset
#' @param algo the forecasting fucntion to use
#' @param startm
#' @param endm
#' @param starty
#' @param endy
#' @param startd
#' @param endd
#' @param freq
plot_forecasting <- function(algo,mydata,startm,starty,endm,endy,startd,endd,freq){
    
  if (!require("ggplot2")) {
    install.packages("ggplot2")
  }
  library(ggplot2)
  if (!require("forecast")) {
    install.packages("forecast")
  }
  library(forecast)
  
  if (!require("zoo")) {
    install.packages("zoo")
  }
  library(zoo)
  start = paste(toString(starty),toString(startm),toString(startd),sep = "-")
  end =  paste(toString(endy),toString(endm),toString(endd),sep = "-")
  
  forecast = forecast((ts(mydata, start=c(startm,startd), 
                          frequency=30)),30)
  forecast_value =  as.numeric(forecast$mean)
  
  data = zoo(mydata, seq(from = as.Date(start), to = as.Date(end), by = 1))
  
  forecast= zoo(forecast_value , seq(from = as.Date(end), to = as.Date(end)+30, by = 1))
  plot(data,col ="green",xlim = c(as.Date(start),as.Date(end)+30))
   
  
  lines(forecast,col ="red")
}

printsummary <- function(algo,mydata,startm,starty,endm,endy,startd,endd,freq){
  if (!require("ggplot2")) {
    install.packages("ggplot2")
  }
  library(ggplot2)
  if (!require("forecast")) {
    install.packages("forecast")
  }
  library(forecast)
  start = paste(toString(starty),toString(startm),toString(startd),sep = "-")
  end =  paste(toString(endy),toString(endm),toString(endd),sep = "-")
  
  forecast = forecast((ts(mydata, start=c(startm,startd), 
                          frequency=30)),30)
  print(forecast)
}
print_model <- function(algo,mydata,startm,starty,endm,endy,startd,endd,freq){
  if (!require("ggplot2")) {
    install.packages("ggplot2")
  }
  library(ggplot2)
  if (!require("forecast")) {
    install.packages("forecast")
  }
  library(forecast)
  start = paste(toString(starty),toString(startm),toString(startd),sep = "-")
  end =  paste(toString(endy),toString(endm),toString(endd),sep = "-")
  
  forecast = forecast((ts(mydata, start=c(startm,startd), 
                          frequency=30)),30)
  print(forecast$model$method)
}
