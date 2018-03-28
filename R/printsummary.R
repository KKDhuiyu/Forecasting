#' Print Summary
#' 
#' Wrapper for summary
#' 
#' @export
#' @param mydata some object or dataset
printsummary <- function(mydata){
  myts <- ts(mydata, start=c(2016, 1), end=c(2017, 12), frequency=12)
  print(forecast(myts))
}