#' Storage Place for HaloBoost Functions 
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

forecast.rf <- function(train, test, Projection, proj_data) {
  # Train a random forest using all default parameters
  rfHex <- randomForest(  x = train[,c(feature.names)],
                          y = train$Target,
                          data = train,
                          ntrees = ntrees,
                          maxnodes = 500,
                          mtry = 0.8*ncol(train),
                          importance = TRUE)
  
  summary(rfHex)
  
  # Importance Matrix
  df <- importance(rfHex, type = 1)
  df <- as.matrix(df[order(df[,1],decreasing = TRUE ),])
  print(df)
  
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
    project <- projection.scoring(project = proj_data, forecast = "RF", model = rfHex)
    output <- rbind(train, test, project)
    output <- output[order(output$Key, output$Date),]
  } else {
    output <- rbind(train, test)
    output <- output[order(output$Key, output$Date),]
  }
  return(output)
  
}

forecast.xgboost <- function (train, test, Projection, proj_data) {
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
    project <- projection.scoring(project = proj_data, forecast = "XGBoost", model = clf)
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


projection.scoring <- function(project, forecast, model) {
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
