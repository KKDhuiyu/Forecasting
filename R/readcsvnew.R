#' Read CSV file
#' 
#' Simple wrapper for read.csv
#' 
#' @export
#' @param file a csv file.
#' @param fileinput a csv file.
#' @param ... arguments passed to read.csv
config <- function(file, ...){
  if(!grepl(".csv$", file)){
    stop("Uploaded file must be a .csv file!")
  }
  read.csv(
    configFile,
    skipNul = T,
    colClasses = "character"
  )
 
}
print(config)
input <- function(fileinput, ...){
  if(!grepl(".csv$", fileinput)){
    stop("Uploaded file must be a .csv file!")
  }
  read.csv(
    fileinput,
    skipNul = T,
    colClasses = "character"
  )
}

print(summary(input))