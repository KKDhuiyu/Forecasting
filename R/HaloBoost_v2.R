# Library ----
#' @export
#' @param configFile a csv file.
#' @param inputFile a csv file.
#' Utility.R 
#' 


`%!in%` = Negate(`%in%`)

create.lag <- function (input, variable, lag_list, specific_lag) {
  # Create lag variables 
  split <- split.data.frame(input, input$Key)
  
  # Split the Target variable by Key 
  y <- lapply(split, `[[`, which(colnames(input) == variable))
  rm(split)
  
  # Create lag varaibles 
  for (i in 1:length(lag_list)) {
    assign(lag_list[i], lapply(y, function(x) {lag(x, i, na.pad = T)}))
    input <- cbind(input, unlist(get(lag_list[i])))
    colnames(input)[ncol(input)] <- lag_list[i]
    rm(list = lag_list[i])
  }
  rm(y)
  gc()
  
  # Delete records with NA within the last lag 
  input <- input[-c(which(is.na(input[,ncol(input)]))),]
  
  return(input)
}

forecast.rf <- function(train, test, Projection, proj_data,feature.names,ntrees,tmp,tmp2,projection,lag_list) {
  # Train a random forest using all default parameters
  rfHex <- randomForest(  x = train[,c(feature.names)],
                          y = train$Target,
                          data = train,
                          ntrees = ntrees,
                          maxnodes = 500,
                          mtry = 0.8*ncol(train),
                          importance = TRUE)
  

  
  # Importance Matrix
  df <- importance(rfHex, type = 1)
  df <- as.matrix(df[order(df[,1],decreasing = TRUE ),])

  
  # RF Prediction
  pred_train_rf <- predict(rfHex,newdata = train)
  pred_test_rf <- predict(rfHex,newdata = test)
  
  # Convert Negative forecast to 0
  pred_test_rf[pred_test_rf < 0] <- 0
  pred_train_rf[pred_train_rf < 0] <- 0
  
  # Final Data cleaning  
  test$Date <- tmp2$date
  test <- cbind(test, predict_rf = pred_test_rf)
  
  train$Date <- tmp$date
  train <- cbind(id = as.numeric(tmp$id), train, predict_rf = pred_train_rf)
  
  if (Projection) {
    # Start Projection Scoring
    project <- projection.scoring(project = proj_data, forecast = "RF", model = rfHex,feature.names,lag_list)
    output <- rbind(train, test, project)
    output <- output[order(output$Key, output$Date),]
  } else {
    output <- rbind(train, test)
    output <- output[order(output$Key, output$Date),]
  }
  return(output)
  
}

forecast.xgboost <- function (train, test, Projection, proj_data,feature.names,eta,max_depth_xgb,nrounds,tmp,tmp2,projection,lag_list) {
  # Define error function
  tra <-train[,feature.names]
  RMPSE <- function(preds, dtrain) {
    labels <- getinfo(dtrain, "label")
    elab <- exp(as.numeric(labels)) - 1
    epreds <- exp(as.numeric(preds)) - 1
    err <- sqrt(mean((epreds/elab-1)^2))
    return(list(metric = "RMPSE", value = err))
  }
  
  # Define Training Sample  
  h <- sample(nrow(train), nrow(train)*0.25)
  
  # Define transformace and watchlist 
  dval <- xgb.DMatrix(data=data.matrix(tra[h,]),label = log(train$Target + 1000)[h])
  dtrain <- xgb.DMatrix(data=data.matrix(tra[-h,]),label = log(train$Target + 1000)[-h])
  watchlist <- list(val=dval,train=dtrain)
  
  # Define XGboost parameter 
  param <- list(  objective           = "reg:linear",
                  booster             = "gbtree",
                  nthreads            = 2,
                  eta                 = eta,        # 0.06, #0.01,
                  max_depth           = max_depth_xgb,  # changed from default of 8
                  subsample           = 0.8,         # 0.7
                  # colsample_bytree    = 0.7       # 0.7
                  # num_parallel_tree   = 2
                  alpha = 0.0001,
                  lambda = 1
  )
  
  # XGboost Training 
  clf <- xgb.train(   params                 = param,
                      data                   = dtrain,
                      nrounds                = nrounds, #300, #280, #125, #250
                      verbose                = 1,
                      early.stopping.rounds  = 100,
                      watchlist              = watchlist,
                      maximize               = FALSE,
                      feval=RMPSE
  )
  summary(clf)
  
  # Prediction 
  pred_test_xgb <- exp(predict(clf, data.matrix(test[,feature.names]))) - 1000
  pred_train_xgb <- exp(predict(clf, data.matrix(train[,feature.names]))) - 1000
  
  # convert Negative forecast to 0 
  pred_test_xgb[pred_test_xgb < 0] <- 0
  pred_train_xgb[pred_train_xgb < 0] <- 0
  
  # Final Data cleaning  
  test$Date <- tmp2$date
  test <- cbind(test
                , predict_xgb = pred_test_xgb
                # , predict_rf = pred_test_rf
  )
  
  train$Date <- tmp$date
  train <- cbind(id = as.numeric(tmp$id), train
                 , predict_xgb = pred_train_xgb
                 # , predict_rf = pred_train_rf
  )
  
  if (Projection) {
    # Start Projection Scoring 
    project <- projection.scoring(project = proj_data, forecast = "XGBoost", model = clf,feature.names,lag_list)
    output <- rbind(train, test, project)
    output <- output[order(output$Key, output$Date),]
  } else {
    output <- rbind(train, test)
    output <- output[order(output$Key, output$Date),]
  }
  return(output)
}

validation <- function (output, forecast) {
  if (forecast == "XGBoost") {
    Agg <- as.data.frame(aggregate(cbind(output$predict_xgb, output$Target), 
                                   by = list(output$Date), FUN = sum))
  }
  if (forecast == "RF") {
    Agg <- as.data.frame(aggregate(cbind(output$predict_rf, output$Target), 
                                   by = list(output$Date), FUN = sum))
  }
  if (forecast == "Ensemble") {
    Agg <- as.data.frame(aggregate(cbind(output$predict_esb, output$Target), 
                                   by = list(output$Date), FUN = sum)) 
  }
  colnames(Agg) <- c("Date" , "Sum_of_Predict", "Sum_of_Actual")
  
  # Accuracy Metrics
  Agg$Var <- (Agg$Sum_of_Actual - Agg$Sum_of_Predict)/Agg$Sum_of_Actual
  Agg$APE <- abs(Agg$Sum_of_Actual - Agg$Sum_of_Predict)/Agg$Sum_of_Actual
  Agg$Date <- ymd(Agg$Date)
  Agg <- Agg[order(Agg$Date),]
  
  return(Agg)
}

# Period Over Period Report 
PoP_valid <- function(data, period) {
  if (period == "month") {
    data$period = as.yearmon(data$Date)
    data_agg <- as.data.frame(aggregate(cbind(data$Sum_of_Predict, data$Sum_of_Actual), 
                                        by = list(data$period), FUN = sum))
    colnames(data_agg) <- c("Month" , "Sum_of_Predict", "Sum_of_Actual")
    
    # Accuracy Metric
    data_agg$Var <- (data_agg$Sum_of_Actual - data_agg$Sum_of_Predict)/
      data_agg$Sum_of_Actual
    data_agg$APE <- abs(data_agg$Sum_of_Actual - data_agg$Sum_of_Predict)/
      data_agg$Sum_of_Actual
    
    data_agg <- data_agg[order(data_agg$Month),]
  }
  if (period == "quarter") {
    data$period = as.yearqtr(data$Date)
    data_agg <- as.data.frame(aggregate(cbind(data$Sum_of_Predict, data$Sum_of_Actual), 
                                        by = list(data$period), FUN = sum))
    colnames(data_agg) <- c("Quarter" , "Sum_of_Predict", "Sum_of_Actual")
    # Accuracy Metric
    data_agg$Var <- (data_agg$Sum_of_Actual - data_agg$Sum_of_Predict)/
      data_agg$Sum_of_Actual
    data_agg$APE <- abs(data_agg$Sum_of_Actual - data_agg$Sum_of_Predict)/
      data_agg$Sum_of_Actual
    
    data_agg <- data_agg[order(data_agg$Quarter),]
  }
  return(data_agg)
}


projection.scoring <- function(project, forecast, model,feature.names,lag_list) {
  # Projection Data clearning 
  for (f in feature.names) {
    if (class(project[[f]])=="character") {
      levels <- unique(project[[f]])
      project[[f]] <- as.integer(factor(project[[f]], levels=levels))
    }
  }
  project[,lag_list] <- lapply(project[,lag_list], as.character)
  project[] <- lapply(project, as.numeric)
  
  if (forecast == "XGBoost") {
    # Create the predict variable
    project$predict_xgb <- 0
    
    # Start Projecting
    split_proj <- split.data.frame(project, project$t)
    
    for (i in 1:(length(split_proj))) {
      x <- exp(predict(model, data.matrix(split_proj[[i]][,feature.names]))) - 1000
      x[x < 0 ] <- 0
      split_proj[[i]]$predict_xgb <- x
      
      if (i != length(split_proj)) {
        for (j in (i + 1):(length(split_proj))) {
          split_proj[[j]][,lag_list[j - i]] <- x
        }
      } 
    }
    
    # Getting back to data frame and sort
    project <- rbind.fill(split_proj)
    project <- project[order(project$id),]
    
    # Convert negative forecast to 0 
    project$predict_xgb[project$predict_xgb < 0] <- 0
  } 
  if (forecast == "RF") {
    # Create the predict variable
    project$predict_rf <- 0
    
    # Start Projecting
    split_proj <- split.data.frame(project, project$t)
    
    for (i in 1:(length(split_proj))) {
      #delete h2o
      x <- as.vector(predict(model, data.matrix(split_proj[[i]][,feature.names])))
      split_proj[[i]]$predict_rf <- x
      
      if (i != length(split_proj)) {
        for (j in (i + 1):(length(split_proj))) {
          split_proj[[j]][,lag_list[j - i]] <- x
        }
      } 
    }
    
    # Getting back to data frame and sort
    project <- rbind.fill(split_proj)
    project <- project[order(project$id),]
    
    # Convert negative forecast to 0 
    project$predict_rf[project$predict_rf < 0] <- 0
  }
  project <- project[order(project$Key, project$Date),]
  project$Date <- holdout$Date
  project$Target <- as.numeric(holdout$Target)
  
  return(project)
}

# Accuracy Functions ---- 
me <- function(actual, predict) {
  x <- mean(actual - predict)
  return(x)
}
rmse <- function(actual, predict) {
  x <- sqrt(mean((actual - predict)^2))
  return(x)
}
mae <- function(actual, predict) {
  x <- mean(abs(actual - predict))
  return(x)
}
mpe <- function(actual, predict) {
  x <- mean((actual - predict) / actual)
  return(x)
}
mape <- function(actual, predict) {
  x <- mean(abs((actual - predict) / actual))
  return(x)
}

mase <- function(actual, predict) {
  # ACF1 is not available for machine learning algorithms 
  # Set default to 0
  x <- 0*mean((actual - predict))
  return(x)
}

acf1 <- function(actual, predict) {
  # ACF1 is not available for machine learning algorithms 
  # Set default to 0
  x <- 0*mean((actual - predict))
  return(x)
}

accuracy.table <- function(input, output) {
  
  table <- data.frame()
  accuracy <- output
  alg <- unique(accuracy$PredictMessage)
  colnames(input)[2:3] <- c(Key, Date)
  tmp3 <- merge(output, input[,2:4], by = c(Key, Date),all.x=TRUE)
  tmp3 <- tmp3[which(tmp3$PredictDate >= valid_start & tmp3$PredictDate <= valid_end),]
  
  for (i in 1:length(alg)) {
    accuracy <- split(tmp3[tmp3$PredictMessage == alg[i],],
                      tmp3[tmp3$PredictMessage == alg[i],]$PredictGroup)
    
    ME <-  unlist(lapply(accuracy, function(x) {me(as.numeric(x[[10]]), as.numeric(x[[4]]))}))
    RMSE <-  unlist(lapply(accuracy, function(x) {rmse(as.numeric(x[[10]]), as.numeric(x[[4]]))}))
    MAE <-  unlist(lapply(accuracy, function(x) {mae(as.numeric(x[[10]]), as.numeric(x[[4]]))}))
    MPE <-  unlist(lapply(accuracy, function(x) {mpe(as.numeric(x[[10]]), as.numeric(x[[4]]))}))
    MAPE <-  unlist(lapply(accuracy, function(x) {mape(as.numeric(x[[10]]), as.numeric(x[[4]]))}))
    MASE <-  unlist(lapply(accuracy, function(x) {mase(as.numeric(x[[10]]), as.numeric(x[[4]]))}))
    ACF1 <-  unlist(lapply(accuracy, function(x) {acf1(as.numeric(x[[10]]), as.numeric(x[[4]]))}))
    
    table <- rbind(table, data.frame(ME, RMSE, MAE, MPE, MAPE, MASE, ACF1, 
                                     PredictGroup = unique(tmp3$PredictGroup), PredictMessage = alg[i]))
    
    # Convert to valid sql data. E.g. +-Inf -> +-1e38
    table[table==Inf] <- 1e38 
    table[table==-Inf] <- -1e38
    table[is.na(table)] <- 0
    
  }
  return(table)
}

defaultsTo <- function(defaultValue, configArray, paramName) {
  paramValue <- defaultValue
  if (paramName %in% configArray$name) {
    paramValue <- configArray[paramName, 2]
  }
  return (paramValue)
}
######################################################################Utility end
######################################################################
######################################################################
######################################################################
######################################################################
######################################################################
##### HaloBoost 2.0 #####

forecasting <- function(configFile,inputFile){
  A <- Sys.time()
  
  
  # Time Zone ----
  Sys.setenv(TZ = 'GMT')
  

  
  if (!require("readr")) {
    install.packages("readr")
  }
  library(readr)
  if (!require("plyr")) {
    install.packages("plyr")
  }
  library(plyr)
  if (!require("dplyr")) {
    install.packages("dplyr")
  }
  library(dplyr)
  if (!require("lubridate")) {
    install.packages("lubridate")
  }
  library(lubridate)
  if (!require("xgboost")) {
    install.packages("xgboost")
  }
  library(xgboost)
  if (!require("ggplot2")) {
    install.packages("ggplot2")
  }
  library(ggplot2)
  if (!require("zoo")) {
    install.packages("zoo")
  }
  library(zoo)
  if (!require("randomForest")) {
    install.packages("randomForest")
  }
  library(randomForest)
  
  # Suppress Warning Messages ----
  options(warn = -1)
  
 
    config <-read.csv(
      configFile,
      skipNul = T,
      colClasses = "character"
    )
  
  
  
  # Config Arguments ----
  row.names(config) <- config$name
  
  Date <- defaultsTo("PredictDate", config, "Date")
  Key <- defaultsTo("PredictGroup", config, "Key")
  Target <- defaultsTo("PredictMeasure", config, "Target")
  
  valid_start <-
    ymd(defaultsTo(Sys.Date(), config, "ValidationStart"))
  valid_period <-
    as.integer(defaultsTo(6, config, "AccuracyPeriodsMinimum"))
  
  XGBoost <-
    as.logical(as.integer(defaultsTo(1, config, "UtilizeXgBoost")))
  RF <- as.logical(as.integer(defaultsTo(1, config, "UtilizeRf")))
  
  projection <- TRUE # we need projection to run future forecast
  
  project_period <-  as.integer(defaultsTo(6, config, "PeriodsCount"))
  
  granularity <- defaultsTo("Week", config, "TimeGranularity")
  
  specific_lag <-
    defaultsTo(NA, config, "Specific_lag") # This should be NA by default
  
  ci <-
    c(
      defaultsTo(0.75, config, "ConfidenceLevel1"),
      defaultsTo(0.9, config, "ConfidenceLevel2")
    )
  
  
  
  # Validation/Projection Scroing/Number of Lag ----
  if (granularity == "Week") {
    valid_end <- valid_start + weeks(valid_period - 1)
    project_start <- valid_end + weeks(1)
    project_end <- project_start + weeks(project_period - 1)
    num_lag <- 52
    
  } else if (granularity == "Month") {
    valid_end <- valid_start + months(valid_period - 1)
    project_start <- valid_end + months(1)
    project_end <- project_start + months(project_period - 1)
    num_lag <- 12
    
  } else if (granularity == "Day") {
    valid_end <- valid_start + days(valid_period - 1)
    project_start <- valid_end + days(1)
    project_end <- project_start + days(project_period - 1)
    num_lag <- 30
    
  } else {
    stop(paste("Time Granularity is not properly defined."))
  }
  
  lag_list <- paste("lag", 1:num_lag, sep = "_")
  col.names <- c(
    "PredictGroup",
    "PredictDate",
    "PredictValue",
    "PredictValue_StdPlus",
    "PredictValue_StdMinus",
    "PredictValue_StdPlus2",
    "PredictValue_StdMinus2",
    "PredictMessage"
  )
  
  # Number of round of Simulation ----
  cf_round <- defaultsTo(2, config, "SimulationRound")
  
  # XGBoost Parameters ----
  eta <- defaultsTo(0.05, config, "XGBoost_eta")
  max_depth_xgb <- defaultsTo(100, config, "XGBoost_max_depth")
  nrounds <- defaultsTo(300, config, "XGBoost_nrounds")
  
  # Random Forest Parameters ----
  ntrees <- defaultsTo(20, config, "RF_ntrees")
  
  # Source utility.R
  # source(paste(path, "\\utility.R", sep = ""))
  input <- read.csv(
      inputFile,
      skipNul = T,
      colClasses = "character")
  

  
  # Standardize the variable name  ----
  names(input)[(names(input) == Date)] <- "Date"
  names(input)[(names(input) == Key)] <- "Key"
  names(input)[(names(input) == Target)] <- "Target"
  
  # Format date variables ----
  input$Date <- ymd(input$Date)

  
  if (granularity == "Day") {
    if (max(input$Date) - min(input$Date) < 60) {
      stop(
        "Insufficient Data. HaloBoost requires at least 60 days of daily data for each PredictGroup."
      )
    }
  } else {
    if (max(input$Date) - min(input$Date) <= 365) {
      stop("Insufficient Data. HaloBoost requires at least one year of data.")
    } else if (max(input$Date) - min(input$Date) <= 547) {
      message("Warning: Data ranges less than 1.5 year. We recommend to add more data to your input.")
    }
  }
  
  # Sort data ----
  input <- input[order(input$Key, input$Date), ]
  
  # Create the variable t ----
  input$t <- with(input, ave(input$Key, input$Key, FUN = seq_along))
  
  if (projection) {
    holdout <-
      input[which(input$Date >= project_start &
                    input$Date <= project_end),
            which(colnames(input) == "Key" |
                    colnames(input) == "Date" |
                    colnames(input) == "Target")]
    input$Target[which(input$Date >= project_start &
                         input$Date <= project_end)] <- ""
    input <- create.lag(
      input = input,
      variable = "Target",
      lag_list = lag_list,
      specific_lag = specific_lag
    )
    project <-
      input[which(input$Date >= project_start &
                    input$Date <= project_end), ]
  } else {
    input <- create.lag(
      input = input,
      variable = "Target",
      lag_list = lag_list,
      specific_lag = specific_lag
    )
    project <- NA
  }
  
  input[lag_list] <- lapply(
    input[lag_list],
    FUN = function(x) {
      x <- as.numeric(as.character(x))
    }
  )
  
  # Declare train, test and project dataset ----
  test <-
    input[which(input$Date >= valid_start & input$Date <= valid_end), ]
  train <- input[which(input$Date < valid_start), ]
  
  # Some Data Prep ----
  tmp <-
    data.frame(
      id = train$id,
      date = train$Date,
      Key = train$Key,
      stringsAsFactors = F
    )
  tmp2 <-
    data.frame(date = test$Date,
               Key = test$Key,
               stringsAsFactors = F)
  train <- train[-c(1)]
  
  # Declare features ----
  feature.names <- names(train)[-c(3)]
  feature.names <- feature.names[feature.names %!in% lag_list[-c(specific_lag)]]
  
  # Convert Character features to factor ----
  for (f in feature.names) {
    if (class(train[[f]]) == "character") {
      levels <- unique(c(train[[f]], test[[f]]))
      train[[f]] <- as.integer(factor(train[[f]], levels = levels))
      test[[f]]  <- as.integer(factor(test[[f]],  levels = levels))
    }
  }
  
  # Convert all variable in train and test to numeric ----
  train[] <- lapply(train, as.numeric)
  test[] <- lapply(test, as.numeric)
  
  # XGBoost forecast ----
  if (XGBoost) {
    # Data frame used in build out confidence interval
    if (projection) {
      cf_xgb <-
        data.frame(
          Key = input$Key[which(input$Date <= project_end)],
          Date = input$Date[which(input$Date <= project_end)],
          Target = input$Target[which(input$Date <= project_end)]
        )
    } else {
      cf_xgb <-
        data.frame(
          Key = input$Key[which(input$Date <= valid_end)],
          Date = input$Date[which(input$Date <= valid_end)],
          Target = input$Target[which(input$Date <= valid_end)]
        )
    }
    
    round <- cf_round
    round_list <- paste("predict", 1:round, sep = "_")
    
    # Simulation Start
    for (i in 1:round) {
      output_xgb <- forecast.xgboost(
        train = train,
        test = test,
        Projection = projection,
        proj_data = project,
        feature.names, eta,max_depth_xgb, nrounds,
        tmp,tmp2,projection,lag_list
        
      )
      # , grid_search = grid_search)
      
      cf_xgb <-
        cbind(cf_xgb,  assign(round_list[i], output_xgb$predict_xgb))
      colnames(cf_xgb)[ncol(cf_xgb)] <- paste("predict", i, sep = "_")
      rm(list = round_list[i])
    }
    
    # Calculate mean and stdv
    pred_names <- colnames(cf_xgb[,-c(1:3)])
    cf_xgb <- cf_xgb %>%
      rowwise() %>%
      do(data.frame(., mean = mean(unlist(.[pred_names])),
                    stdev = sd(unlist(.[pred_names]))))
    
    # Compute confidence interval
    cf_xgb$upper1 <- cf_xgb$mean + qnorm(ci[1]) * cf_xgb$stdev
    cf_xgb$lower1 <- cf_xgb$mean - qnorm(ci[1]) * cf_xgb$stdev
    cf_xgb$upper2 <- cf_xgb$mean + qnorm(ci[2]) * cf_xgb$stdev
    cf_xgb$lower2 <- cf_xgb$mean - qnorm(ci[2]) * cf_xgb$stdev
    cf_xgb <- cf_xgb[, !names(cf_xgb) %in% pred_names]
    
    # Change colname mean to predict_xgb
    colnames(cf_xgb)[4] <- "predict_xgb"
  }
  
  # Random Forest forecast ----
  if (RF) {
    # Data frame used in build out confidence interval
    if (projection) {
      cf_rf <-
        data.frame(
          Key = input$Key[which(input$Date <= project_end)],
          Date = input$Date[which(input$Date <= project_end)],
          Target = input$Target[which(input$Date <= project_end)]
        )
    } else {
      cf_rf <-
        data.frame(
          Key = input$Key[which(input$Date <= valid_end)],
          Date = input$Date[which(input$Date <= valid_end)],
          Target = input$Target[which(input$Date <= valid_end)]
        )
    }
    round <- cf_round
    round_list <- paste("predict", 1:round, sep = "_")
    
    # Simulation Start
    for (i in 1:round) {
      output_rf <- forecast.rf(
        train = train,
        test = test,
        Projection = projection,
        proj_data = project
        ,feature.names,ntrees,tmp,tmp2,projection,lag_list
        
      )
      
      cf_rf <-
        cbind(cf_rf,  assign(round_list[i], output_rf$predict_rf))
      colnames(cf_rf)[ncol(cf_rf)] <- paste("predict", i, sep = "_")
      rm(list = round_list[i])
    }
    
    # Calculate mean and stdv
    pred_names <- colnames(cf_rf[,-c(1:3)])
    cf_rf <- cf_rf %>%
      rowwise() %>%
      do(data.frame(., mean = mean(unlist(.[pred_names])),
                    stdev = sd(unlist(.[pred_names]))))
    
    # Compute confidence interval
    cf_rf$upper1 <- cf_rf$mean + qnorm(ci[1]) * cf_rf$stdev
    cf_rf$lower1 <- cf_rf$mean - qnorm(ci[1]) * cf_rf$stdev
    cf_rf$upper2 <- cf_rf$mean + qnorm(ci[2]) * cf_rf$stdev
    cf_rf$lower2 <- cf_rf$mean - qnorm(ci[2]) * cf_rf$stdev
    cf_rf <- cf_rf[, !names(cf_rf) %in% pred_names]
    
    # Change colname mean to predict_rf
    colnames(cf_rf)[4] <- "predict_rf"
    
  }
  
  # Validation ----
  if (XGBoost) {
    valid_xgb <- validation(output = output_xgb, forecast = "XGBoost")
    print(valid_xgb)
    cat("\n")
    
    # # Output
    output_xgb <- output_xgb[, which(
      colnames(output_xgb) == "Key" |
        colnames(output_xgb) == "Date" |
        colnames(output_xgb) == "predict_xgb"
    )]
    # Matching SQL Format ----
    output_xgb$PredictValue_StdPlus <- cf_xgb$upper1
    output_xgb$PredictValue_StdMinus <- cf_xgb$lower1
    output_xgb$PredictValue_StdPlus2 <- cf_xgb$upper2
    output_xgb$PredictValue_StdMinus2 <- cf_xgb$lower2
    output_xgb$PredictMessage <- "XGB"
    
    
    
    #valid_xgbation Plot
    print(
      ggplot(data = valid_xgb) +
        geom_line(
          aes(
            y = valid_xgb$Sum_of_Predict,
            x = valid_xgb$Date,
            color = "Predict"
          ),
          stat = "identity"
        ) +
        geom_line(
          aes(
            y = valid_xgb$Sum_of_Actual,
            x = valid_xgb$Date,
            color = "Actual"
          ),
          stat = "identity"
        ) +
        scale_colour_manual(
          "",
          breaks = c("Predict", "Actual"),
          values = c("red", "green")
        ) +
        ggtitle("Actual versus XGboost Forecast") +
        labs(y = Target, x = Date)
    )
    
    # Period over period valid_xgbation
    valid_xgb_mon <- PoP_valid(data = valid_xgb, period = "month")
    print(valid_xgb_mon)
    cat('\n')
    
    valid_xgb_qtr <- PoP_valid(data = valid_xgb, period = "quarter")
    print(valid_xgb_qtr)
    cat('\n')
    
    # Variance calculation ----
    cat(
      "The variance of the XGBoost Model is",
      (
        sum(valid_xgb$Sum_of_Actual[which(valid_xgb$Date >= valid_start &
                                            valid_xgb$Date <= valid_end)]) -
          sum(valid_xgb$Sum_of_Predict[which(valid_xgb$Date >= valid_start &
                                               valid_xgb$Date <= valid_end)])
      ) /
        sum(valid_xgb$Sum_of_Actual[which(valid_xgb$Date >= valid_start &
                                            valid_xgb$Date <= valid_end)]),
      "\n"
    )
    cat("\n")
    cat("The MAPE of the XGBoost Model is",
        mean(valid_xgb$APE[which(valid_xgb$Date >= valid_start &
                                   valid_xgb$Date <= valid_end)]), "\n")
  }
  
  if (RF) {
    # Validation
    valid_rf <- validation(output = output_rf, forecast = "RF")
    print(valid_rf)
    cat('\n')
    
    output_rf <- output_rf[, which(
      colnames(output_rf) == "Key" |
        colnames(output_rf) == "Date" |
        colnames(output_rf) == "predict_rf"
    )]
    # Matching SQL Format ----
    output_rf$PredictValue_StdPlus <- cf_rf$upper1
    output_rf$PredictValue_StdMinus <- cf_rf$lower1
    output_rf$PredictValue_StdPlus2 <- cf_rf$upper2
    output_rf$PredictValue_StdMinus2 <- cf_rf$lower2
    output_rf$PredictMessage <- "RF"
    
    # Validation Plot
    print(
      ggplot(data = valid_rf) +
        geom_line(
          aes(
            y = valid_rf$Sum_of_Predict,
            x = valid_rf$Date,
            color = "Predict"
          ),
          stat = "identity"
        ) +
        geom_line(
          aes(
            y = valid_rf$Sum_of_Actual,
            x = valid_rf$Date,
            color = "Actual"
          ),
          stat = "identity"
        ) +
        scale_colour_manual(
          "",
          breaks = c("Predict", "Actual"),
          values = c("red", "green")
        ) +
        ggtitle("Actual versus Random Forest Forecast") +
        labs(y = Target, x = Date)
    )
    
    # Period over period validation
    valid_rf_mon <- PoP_valid(data = valid_rf, period = "month")
    print(valid_rf_mon)
    cat('\n')
    
    valid_rf_qtr <- PoP_valid(data = valid_rf, period = "quarter")
    print(valid_rf_qtr)
    cat('\n')
    
    # Variance calculation
    cat(
      "The variance of the Random Forest Model is",
      (
        sum(valid_rf$Sum_of_Actual[which(valid_rf$Date >= valid_start &
                                           valid_rf$Date <= valid_end)]) -
          sum(valid_rf$Sum_of_Predict[which(valid_rf$Date >= valid_start &
                                              valid_rf$Date <= valid_end)])
      ) /
        sum(valid_rf$Sum_of_Actual[which(valid_rf$Date >= valid_start &
                                           valid_rf$Date <= valid_end)]),
      "\n"
    )
    cat("\n")
    cat("The MAPE of the Random Forest Model is",
        mean(valid_rf$APE[which(valid_rf$Date >= valid_start &
                                  valid_rf$Date <= valid_end)]),
        "\n")
  }
  
  # Ensemble model ----
  if (XGBoost & RF) {
    output_esb <-
      merge(output_rf[, 1:3], output_xgb[, 1:3], by = c("Key", "Date"))
    output_esb <- output_esb[order(output_esb$Key,
                                   output_esb$Date), ]
    # If we enable projection scoring
    if (projection) {
      output_esb$Key <- input$Key[which(input$Date <= project_end)]
      output_xgb$Key <- input$Key[which(input$Date <= project_end)]
      output_rf$Key <- input$Key[which(input$Date <= project_end)]
    } else {
      output_esb$Key <- input$Key[which(input$Date <= valid_end)]
      output_xgb$Key <- input$Key[which(input$Date <= valid_end)]
      output_rf$Key <- input$Key[which(input$Date <= valid_end)]
    }
    
    # Calculate Ensemble results
    output_esb$predict_esb <-
      (output_esb$predict_rf + output_esb$predict_xgb) / 2
    output_esb <- output_esb[, -c(3, 4)]
    
    # Calculate Enseble confidence interval
    output_esb$PredictValue_StdPlus <-
      output_esb$predict_esb  + qnorm(ci[1]) * sqrt((cf_rf$stdev ^ 2 + cf_xgb$stdev ^
                                                       2))
    output_esb$PredictValue_StdMinus <-
      output_esb$predict_esb  - qnorm(ci[1]) * sqrt((cf_rf$stdev ^ 2 + cf_xgb$stdev ^
                                                       2))
    output_esb$PredictValue_StdPlus2 <-
      output_esb$predict_esb  + qnorm(ci[2]) * sqrt((cf_rf$stdev ^ 2 + cf_xgb$stdev ^
                                                       2))
    output_esb$PredictValue_StdMinus2 <-
      output_esb$predict_esb  - qnorm(ci[2]) * sqrt((cf_rf$stdev ^ 2 + cf_xgb$stdev ^
                                                       2))
    output_esb$PredictMessage <- "ESB"
    
    # Assign column names
    colnames(output_esb) <- col.names
    colnames(output_xgb) <- col.names
    colnames(output_rf) <- col.names
    
    # Combine results
    final_output <- rbind(output_xgb, output_rf, output_esb)
    final_output <-
      cbind(rownames = row.names(final_output), final_output)
    write_csv(final_output, 'output_csv.csv', col_names = TRUE)
    
    # Accuracy results
    accuracy_output <-
      accuracy.table(input = input, output = final_output)
    accuracy_output <-
      cbind(rownames = row.names(accuracy_output), accuracy_output)
    write_csv(accuracy_output, 'accuracy_csv.csv')
  }
  
  # Write out files if just one model ----
  if (!XGBoost) {
    # If we enable projection scoring
    if (projection) {
      output_rf$Key <- input$Key[which(input$Date <= project_end)]
    } else {
      output_rf$Key <- input$Key[which(input$Date <= valid_end)]
    }
    
    # Assign column names and combine results
    colnames(output_rf) <- col.names
    output_rf <- cbind(rownames = row.names(output_rf), output_rf)
    write_csv(output_rf, 'output_csv.csv', col_names = TRUE)
    
    # Accuracy results
    accuracy_output <-
      accuracy.table(input = input, output = output_rf)
    accuracy_output <-
      cbind(rownames = row.names(accuracy_output), accuracy_output)
    write_csv(accuracy_output,  'accuracy_csv.csv')
    
  } else if (!RF) {
    if (projection) {
      output_xgb$Key <- input$Key[which(input$Date <= project_end)]
    } else {
      output_xgb$Key <- input$Key[which(input$Date <= valid_end)]
    }
    # Assign column names and combine results
    colnames(output_xgb) <- col.names
    output_xgb <- cbind(rownames = row.names(output_xgb), output_xgb)
    write_csv(output_xgb,  'output_csv.csv', col_names = TRUE)
    
    # Accuracy results
    accuracy_output <-
      accuracy.table(input = input, output = output_xgb)
    accuracy_output <-
      cbind(rownames = row.names(accuracy_output), accuracy_output)
    write_csv(accuracy_output, 'accuracy_csv.csv')
  }
  
  # Time Stamp B ----
  B <- Sys.time()
  print(B-A)

}
