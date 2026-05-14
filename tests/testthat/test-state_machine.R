context("test-state_machine.R")

# Test the state machine functions

describe("estimate_state", {
  
  # Create synthetic time series data
  time <- seq.POSIXct(
    from = as.POSIXct("2023-01-01"),
    by = "1 hour",
    length.out = 100
  )
  
  # Create synthetic discharge data with trend
  y <- c(
    rep(10, 20),  # Baseflow
    seq(10, 30, length.out = 20),  # Rising
    seq(30, 25, length.out = 20),  # Peak and falling
    seq(25, 10, length.out = 40)   # Return to baseflow
  )
  
  it("returns a list with required components", {
    result <- estimate_state(time, y)
    
    expect_is(result, "list")
    expect_true("time_numeric" %in% names(result))
    expect_true("x" %in% names(result))
    expect_true("dx" %in% names(result))
    expect_true("ddx" %in% names(result))
  })
  
  it("returns vectors of same length as input", {
    result <- estimate_state(time, y)
    
    expect_equal(length(result$x), length(y))
    expect_equal(length(result$dx), length(y))
    expect_equal(length(result$ddx), length(y))
  })
  
  it("handles numeric time input", {
    numeric_time <- as.numeric(time)
    result <- estimate_state(numeric_time, y)
    
    expect_is(result, "list")
    expect_equal(length(result$x), length(y))
  })
  
  it("handles POSIXct time input", {
    result <- estimate_state(time, y)
    
    expect_is(result, "list")
    expect_equal(length(result$x), length(y))
  })
  
  it("allows different time unit specifications", {
    for (units in c("secs", "mins", "hours", "days")) {
      result <- estimate_state(time, y, time_units = units)
      expect_is(result, "list")
    }
  })
  
  it("allows different derivative unit specifications", {
    for (units in c("per_second", "per_minute")) {
      result <- estimate_state(time, y, derivative_units = units)
      expect_is(result, "list")
    }
  })
  
  it("throws error for invalid time input", {
    expect_error(
      estimate_state("invalid", y)
    )
  })
  
  it("handles data with missing values", {
    y_with_na <- y
    y_with_na[c(10, 20, 30)] <- NA
    
    result <- estimate_state(time, y_with_na)
    expect_is(result, "list")
  })
  
  it("produces smoothed output", {
    result <- estimate_state(time, y, kernel_l = 60)
    
    # Smoothed values should be less variable than original
    original_var <- var(y, na.rm = TRUE)
    smoothed_var <- var(result$x, na.rm = TRUE)
    
    expect_true(smoothed_var <= original_var)
  })
  
})
