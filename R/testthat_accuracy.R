# Library ----
if (!require("testthat")) {
  install.packages("testthat")
}
library(testthat)

# Testing  ----
# all tests are atomic 
source('C:/Program Files/iQ4bis/HaloSource/RScripts/utility.R')


test_me <- function() {
  a <- c(3, 7, 9, 11) 
  b <- c(3, 7, 9, 11, 13,15,17)
  c <- c(2, 4, 6, 10) 
  d = c()
  print("array a is 3, 7, 9, 11")
  print("array b is 3, 7, 9, 11, 13, 15, 17")
  print("array c is 2, 4, 6, 10")
  print("array d is empty")
  print("1. actual and predict should have same number of elements. ")
  print("2. should arise an error when asked to calculate mean value of 2 empty arrays. ")
  expect_error(me(a,b)) # actual and predict should have same number of elements. 
  expect_error(me(d,d)) # should arise an error when asked to calculate mean value of 2 empty arrays 
  expect_equal(me(a,a),0)
  expect_equal(me(a,c),2)
}
test_me()

test_rmse <- function() {
  a <- c(3, 7, 9, 11) 
  b <- c(3, 7, 9, 11, 13,15,17)
  c <- c(19, 7,9 , 11) 
  d = c()
  print("array a is 3, 7, 9, 11")
  print("array b is 3, 7, 9, 11, 13, 15, 17")
  print("array c is 19, 7, 9 , 11")
  print("array d is empty")
  print("1. actual and predict should have same number of elements. ")
  print("2. should arise an error when asked to calculate mean value of 2 empty arrays. ")
  expect_error(rmse(a,b)) # actual and predict should have same number of elements. 
  expect_error(rmse(d,d)) # should arise an error when asked to calculate RMS value of 2 empty arrays 
  expect_equal(rmse(a,a),0)
  expect_equal(rmse(a,c),8)
}
test_rmse()



