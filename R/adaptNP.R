# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   https://r-pkgs.org
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'
#   GitHub help:
#   https://resources.github.com/github-and-rstudio/
#' Print hello
#'
#' Print hello
#' @examples
#' \dontrun{
#' #' hello()
#' }
hello <- function() {
  print("Hello, world!")
}


# regularWQsampling <- function() {
#
#   #https://doi.org/10.3389/frsc.2021.791595
#   print("Implements methods in the literature")
# }
#
# # - autonomous vehicle: https://asco.lcsr.jhu.edu/adaptive-sampling/
# # - W-WaveNet: A multi-site water quality prediction model incorporating adaptive graph convolution and CNN-LSTM: https://doi.org/10.1371%2Fjournal.pone.0276155
# # - A predictive model of recreational water quality based on adaptive synthetic sampling algorithms and machine learning https://doi.org/10.1016/j.watres.2020.115788
#


#' Find clusters and optimize the number of clusters
#'
#' Given a data frame as input the function will calculate the clusters.
#' @param x numeric matrix of data, or an object that can be coerced to such a matrix (such as a numeric vector or a data frame with all numeric columns).
#' @return Returns a vector of factors representing arbitrary cluster number of the data_frame provided
#' @examples
#' \dontrun{
#' data_frame <- datasets::USArrests
#' clusters <- find_clusters(datasets::USArrests)
#' }

#### add library as dependency: usethis::use_package('stats')
#### add library as dependency: usethis::use_import_from('datasets','USArrests')
#### add library as dependency: usethis::use_import_from('stats','kmeans')


find_clusters = function(x){  # automatically employ elbows method (last point to have reduction of misfit by >25%)
  set.seed(200) # for reproducibility

  # Nbclust: https://www.datanovia.com/en/lessons/determining-the-optimal-number-of-clusters-3-must-know-methods/
  #f_of_x <- splinefun(x,sin(pi/x))
  #f_of_x(x,deriv = 1) # take first derivative of function
  x2 = x[complete.cases(x),]
  clusters = rep(NA, length(x))
  k_candidate = 1:10 # no gaps
  misfit_k = rep(NA, length(k_candidate))
  i=1
  for (k in k_candidate) {
    misfit_k[i] = stats::kmeans(scale(x2),k)$tot.withinss
    i = i+1
  }
  ratio = misfit_k[2:length(misfit_k)]/misfit_k[1:length(misfit_k)-1]
  k_opt = max(which(ratio <0.75)) + 1 # add error handling, set default to 5
  clusters[complete.cases(x2)] = stats::kmeans(scale(x2),k_opt)$cluster
  #return(as.factor(clusters))
  return(flexclust::as.kcca(stats::kmeans(scale(x2),k_opt), scale(x2)))
}

#' Predict cluster membership for new data
#'
#' Assigns cluster labels to new observations using a previously fitted
#' clustering model (e.g. from \code{\link{find_cluster}}). The function
#' applies the same feature structure as the training data and appends
#' predicted cluster states to the input data frame.
#'
#' @param clusters A fitted clustering model object (e.g. `kcca` object)
#'   returned by \code{\link{adaptNP::find_cluster}}. Must support
#'   \code{predict()} and contain training feature ranges in `@xrange`.
#' @param newdata A data frame containing new observations to classify.
#'   Must include all variables used to train the clustering model.
#' @param option Character string specifying how predictions are applied.
#'   Options are:
#'   \itemize{
#'     \item `"same"` (default): predict cluster for each row in `newdata`
#'     \item `"daily"`: aggregate data to daily means before prediction
#'     \item `"daily9am"`: placeholder (not yet implemented)
#'   }
#'
#' @return A data frame equal to `newdata` with an additional column:
#' \itemize{
#'   \item `state`: predicted cluster label for each observation
#' }
#'
#' @details
#' The function ensures that `newdata` contains all variables used to train
#' the clustering model. Only these variables are used in prediction.
#'
#' For `option = "same"`, cluster labels are predicted directly for each
#' observation.
#'
#' For `option = "daily"`, the data are aggregated to daily resolution
#' (using mean values of numeric columns) before prediction. The resulting
#' cluster labels are then mapped back to the original data.
#'
#' Input variables are scaled using \code{scale()} before prediction.
#'
#' Currently, automatic detection of timestamp columns is limited and assumes
#' a column named `TIMESTAMP` when using `"daily"` aggregation.
#'
#' @section Warning:
#' \itemize{
#'   \item The function assumes `newdata` contains a `TIMESTAMP` column for
#'   daily aggregation.
#'   \item The `"daily9am"` option is not yet implemented and will result
#'   in an error.
#'   \item No validation is performed on scaling consistency with the
#'   original training data.
#' }
#'
#' @examples
#' # Example: predict clusters for new data
#' \dontrun{
#' # Fit clustering model
#' model <- adaptNP::find_cluster(training_data)
#'
#' # Predict cluster states for new observations
#' newdata$TIMESTAMP <- Sys.time() + seq_len(nrow(newdata))
#'
#' result <- pred_clusters(
#'   clusters = model,
#'   newdata = newdata,
#'   option = "same"
#' )
#'
#' head(result$state)
#' }
#'
#' @seealso \code{\link{find_cluster}}, \code{\link[stats]{predict}}
#'
#' @export
pred_clusters = function(clusters,newdata, option='same'){

# 1. check column names exist
if ('state' %in% colnames(newdata) == TRUE) {
  print("state column detected. Note new states will be predicted.")
}
if (!all(colnames(clusters@xrange) %in% colnames(newdata)) == TRUE) {
  stop("new data frame must contain all columns from clusters")
}
  
# 2. extract columns and make sure other is right
  tempdata = newdata |> dplyr::select(colnames(clusters@xrange))

# 3. make predictions
  if (option == 'same') {
    state = predict(clusters, scale(tempdata))
    newdata = newdata |> mutate(state = state)
  } else if (option == 'daily9am') {
    # aggregate data daily before clustering
    # find first column is date or dttm >> TODO

  } else if (option == 'daily') {
   # need some way to detect time stamp DTTM column >> TODO  

    tempdata = newdata  |> 
      group_by(lubridate::date(TIMESTAMP )) |> 
      summarise(across(where(is.numeric), mean, na.rm = TRUE)) |> 
      dplyr::rename(DATE = 'lubridate::date(TIMESTAMP)')

    tempdates = tempdata |> dplyr::select(DATE)
    tempdata = tempdata |> dplyr::select(colnames(clusters@xrange))
    state = predict(clusters, scale(tempdata))

    tempdates = tempdates |> mutate(state = state)

    newdata  |> 
      mutate(DATE = lubridate::date(TIMESTAMP)) |> 
      left_join(tempdates, by='DATE')

    # broadcast back to original dataframe


  } else if (option == 'daily9am') {
   stop("option not implmented")
  } else {
    stop("option not implmented")

  }
  return(newdata)
}

#' Flag event given a user-defined craiteria
#'
#' Given a data frame as input the function will flag rows of data that are part of an event.
#' @param df a dataframe containing columns of data, with timestamp in either date, datetime, or dttm format.
#' @param flag_statement dplyr style criteria
#' @return Returns a vector of factors representing arbitrary cluster number of the data_frame provided
#' @examples
#' \dontrun{
#' flag_statement = '(Sonde1_Temperature > 15) | (Sonde1_pH >7)'  # must pass a string
#' flag_event(sonde_data,criteria)
#' }

flag_event <- function(df, flag_statement){
  if(!is.character(flag_statement)) {stop("Error: please put quotes around your flag criteria statement.")}
  # warn user if event_flag column already exist?
  if (any(names(df) == "event_flag")) {
    warning("The column 'event_flag' exists in the data frame.")
  }

  df <- df %>%
    mutate(event_flag = ifelse(eval(rlang::parse_expr(flag_statement)),TRUE,FALSE))
  return(df)
}


# flag_event(sonde_data, sonde_data$Sonde1_Temperature > 15) ## This works

#' Extract periods of events (given minimum segment length)
#'
#' Given a data frame as input the function will calculate the clusters.
#' @param df a dataframe containing columns of data, with timestamp in either date, datetime, or dttm format.
#' @param min_length minimum length of the event
#' @return Returns a df of events with the columns `start` and `end` date (or datetime).
#' @examples
#' \dontrun{
#' extract_event_periods(
#'     sonde_data %>%
#'       rename(timestamp=TIMESTAMP,flag=event_flag),
#'        min_length=50)
#' }

extract_event_periods <- function(df, min_length = 10){

  # generated by chatGPT-- to double check
  # Ensure the dataframe is sorted by timestamp
  df <- df[order(df$timestamp), ]

  # Initialize variables
  event_periods <- list()
  current_period <- NULL

  # Loop through the data to identify consecutive TRUE flags
  for (i in 1:nrow(df)) {
    if (df$flag[i] == TRUE) {
      if (is.null(current_period)) {
        # Start a new period when a TRUE flag is encountered
        current_period <- df$timestamp[i]
      }
      # If this is the last row or the next flag is FALSE, finalize the period
      if (i == nrow(df) || df$flag[i + 1] == FALSE) {
        end_time <- df$timestamp[i]
        # Check if the period contains at least min_length (e.g.5) consecutive TRUE flags
        consecutive_flags <- sum(df$timestamp >= current_period & df$timestamp <= end_time & df$flag == TRUE)
        if (consecutive_flags >= min_length) {
          event_periods <- append(event_periods, list(list(start = current_period, end = end_time)))
        }
        # Reset current period to NULL after checking the condition
        current_period <- NULL
      }
    }
  }

  # convert resultant list to data frame
  event_periods <- event_periods|> 
    jsonlite::toJSON(auto_unbox = TRUE) |>  
    jsonlite::fromJSON( flatten = TRUE)  
  
  return(event_periods)
}


