#' Print Summary
#' 
#' Wrapper for summary
#' 
#' @export
#' @param mydata some object or dataset
printsummary <- function(mydata){
  print(summary(mydata))
  print(mydata)
  print("get called"")
}