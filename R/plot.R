#' MakePlot
#' 
#' @export
#' @param mydata some object or dataset
#' @param algo the forecasting fucntion to use
#' 
#' 
plot_forecasting <- function(mydata,algo){
  # months = c ("1","2","3","4","5","6","7","8","9","10","11","12")
  # value1 = c(1,2,3,4,5,6,7,8,9,10,11,12)
  # value2 = c(2,4,6,8,10,12,14,16,18,20,22,24)
  
  # myvector = c(value1,value2)
  if (!require("ggplot2")) {
    install.packages("ggplot2")
  }
  library(ggplot2)
  if (!require("forecast")) {
    install.packages("forecast")
  }
  library(forecast)
  algorithm = algo
  
  myts <- ts(mydata, start=c(2016, 1), end=c(2017, 12), frequency=12)
  if(algorithm == "ets"){
    print(autoplot(forecast(ets(myts))))
  }else if(algorithm == "ARIMA"){
    print(autoplot(forecast(auto.arima(myts))))
  }else{
    print(autoplot(forecast(myts)))
  }
}


