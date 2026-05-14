context("test-pred_clusters.R")

# Test the pred_clusters function

describe("pred_clusters", {
  
  # Create training and test data
  set.seed(42)
  train_data <- data.frame(
    var1 = c(rnorm(30, mean = 0, sd = 1), rnorm(30, mean = 5, sd = 1)),
    var2 = c(rnorm(30, mean = 0, sd = 1), rnorm(30, mean = 5, sd = 1)),
    var3 = c(rnorm(30, mean = 0, sd = 1), rnorm(30, mean = 5, sd = 1))
  )
  
  test_data <- data.frame(
    var1 = c(rnorm(10, mean = 0, sd = 1), rnorm(10, mean = 5, sd = 1)),
    var2 = c(rnorm(10, mean = 0, sd = 1), rnorm(10, mean = 5, sd = 1)),
    var3 = c(rnorm(10, mean = 0, sd = 1), rnorm(10, mean = 5, sd = 1))
  )
  
  it("adds state column to output", {
    model <- adaptNP::find_clusters(train_data)
    result <- pred_clusters(model, test_data, option = "same")
    
    expect_true("state" %in% colnames(result))
  })
  
  it("returns data frame with same number of rows as input", {
    model <- adaptNP::find_clusters(train_data)
    result <- pred_clusters(model, test_data, option = "same")
    
    expect_equal(nrow(result), nrow(test_data))
  })
  
  it("preserves all original columns", {
    model <- adaptNP::find_clusters(train_data)
    result <- pred_clusters(model, test_data, option = "same")
    
    original_cols <- colnames(test_data)
    expect_true(all(original_cols %in% colnames(result)))
  })
  
  it("predicts numeric state values", {
    model <- adaptNP::find_clusters(train_data)
    result <- pred_clusters(model, test_data, option = "same")
    
    expect_true(is.numeric(result$state))
    expect_true(all(!is.na(result$state)))
  })
  
  it("throws error when required columns are missing", {
    model <- adaptNP::find_clusters(train_data)
    
    incomplete_data <- test_data[, 1:2]
    
    expect_error(
      pred_clusters(model, incomplete_data, option = "same")
    )
  })
  
  it("warns when state column already exists", {
    model <- adaptNP::find_clusters(train_data)
    test_data_with_state <- test_data
    test_data_with_state$state <- rep(1, nrow(test_data))
    
    expect_warning(
      pred_clusters(model, test_data_with_state, option = "same")
    )
  })
  
  it("handles option = 'same' correctly", {
    model <- adaptNP::find_clusters(train_data)
    result <- pred_clusters(model, test_data, option = "same")
    
    expect_equal(nrow(result), nrow(test_data))
    expect_true("state" %in% colnames(result))
  })
  
})
