#' Read CSV file
#' 
#' Simple wrapper for read.csv
#' 
#' @export
#' @param config a csv file.
#' @param input a csv file.

readconfig <- function(config){
  if(!grepl(".csv$", config)){
    stop("Uploaded file must be a .csv file!")
  }
  read.csv(config);
}

readinput <- function(input){
  if(!grepl(".csv$", input)){
    stop("Uploaded file must be a .csv file!")
  }
  read.csv(input);
}
