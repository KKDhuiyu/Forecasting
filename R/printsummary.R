#' Print Summary
#' 
#' Wrapper for summary
#' 
#' @export
#' @param mydata some object or dataset

printsummary <- function(mydata){
  if (!require("ggplot2")) {
    install.packages("ggplot2")
  }
  library(ggplot2)
  if (!require("forecast")) {
    install.packages("forecast")
  }
  library(forecast)
  myts <- ts(mydata, start=c(2016, 1), end=c(2017, 12), frequency=12)
  print(forecast(myts))
}