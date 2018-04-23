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
  
  ts = ts(mydata, start=c(startm,startd), frequency=30)
  if (algo == "ets"){
    forecast = forecast(ets(ts),30)
    print(forecast$method)
  }else if(algo == "ARIMA"){
    forecast = forecast(auto.arima(ts),30)
    print(forecast$method)
  }else if(algo == "stlf"){
    forecast = forecast(stlf(ts),30)
    print(forecast$method)
  }else{
    forecast = forecast((ts),30)
    print(forecast$model$method)
  }
  
}


plot_decomposition <- function(algo,mydata,startm,starty,endm,endy,startd,endd,freq){
  
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
  
  decomposition = mstl((ts(mydata, start=c(startm,startd), 
                          frequency=30)))
  
  len = length(mydata)
  data = decomposition[1:len]
  trend = decomposition[(len+1):(2*len)]
  seasonal = decomposition[(2*len+1):(3*len)]
  remainder = decomposition[(3*len+1):(4*len)]
  
  data = zoo(data, seq(from = as.Date(start), to = as.Date(end), by = 1))
  trend = zoo(data, seq(from = as.Date(start), to = as.Date(end), by = 1))
  seasonal = zoo(data, seq(from = as.Date(start), to = as.Date(end), by = 1))
  remainder = zoo(data, seq(from = as.Date(start), to = as.Date(end), by = 1))
  
 
  autoplot(decomposition)
}

get_csv <- function(algo,mydata,startm,starty,endm,endy,startd,endd,freq){
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
  if(freq=="Date"){
    ts = ts(mydata, start=c(startm,startd), frequency=30)
  }else if(freq=="Month"){
    ts = ts(mydata, start=c(starty,startm), frequency=12)
  } else if(freq=="Quarter"){
    ts = ts(mydata, start=c(startm,startd), frequency=4)
  } else {
    ts = ts(mydata, start=c(starty), frequency=1)
  } 
  
  if (algo == "ets"){
    forecast = forecast(ets(ts),30)

  }else if(algo == "ARIMA"){
    forecast = forecast(auto.arima(ts),30)
  
  }else if(algo == "stlf"){
    forecast = forecast(stlf(ts),30)

  }else{
    forecast = forecast((ts),30)

  }

  forecast_value =  as.numeric(forecast$mean)
  data = zoo(mydata, seq(from = as.Date(start), to = as.Date(end), by = 1))
  forecast_data= zoo(forecast_value , seq(from = as.Date(end), to = as.Date(end)+30, by = 1))
  
  original_data <- data.frame(
    Date = index(data),
    Value = coredata(data)
  )
  
  forecast_data <- data.frame(
    Date = index(forecast_data),
    Value = coredata(forecast_data)
  )
  all_data <- rbind(original_data,forecast_data)
  # all_data <- split(all_data, seq(nrow(all_data)))
  print(all_data)
}


