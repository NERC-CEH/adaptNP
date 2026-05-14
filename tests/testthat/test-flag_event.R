context("test-flag_event.R")

# Test the flag_event function

describe("flag_event", {
  
  # Create sample data for testing
  sample_data <- data.frame(
    timestamp = seq.POSIXct(
      from = as.POSIXct("2023-01-01 00:00:00"),
      by = "1 hour",
      length.out = 24
    ),
    temperature = c(
      10, 12, 14, 16, 18, 20, 22, 24, 25, 26, 25, 24,
      22, 20, 18, 16, 14, 12, 11, 10, 9, 8, 7, 6
    ),
    pH = c(
      7.0, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.8, 7.7,
      7.6, 7.5, 7.4, 7.3, 7.2, 7.1, 7.0, 6.9, 6.8, 6.7, 6.6, 6.5
    )
  )
  
  it("returns a data frame with event_flag column", {
    result <- flag_event(sample_data, "(temperature > 15) & (pH > 7.2)")
    expect_true("event_flag" %in% colnames(result))
    expect_true(is.logical(result$event_flag))
  })
  
  it("correctly flags events matching OR criteria", {
    result <- flag_event(sample_data, "(temperature > 24) | (pH > 7.8)")
    # At least one row should be TRUE
    expect_true(any(result$event_flag == TRUE))
  })
  
  it("correctly flags events matching AND criteria", {
    result <- flag_event(sample_data, "(temperature > 20) & (pH > 7.4)")
    expect_true(any(result$event_flag == TRUE))
  })
  
  it("returns all FALSE for impossible criteria", {
    result <- flag_event(sample_data, "(temperature > 1000) & (pH < 0)")
    expect_true(all(result$event_flag == FALSE))
  })
  
  it("throws error when flag_statement is not a character", {
    expect_error(
      flag_event(sample_data, sample_data$temperature > 15)
    )
  })
  
  it("returns original data plus event_flag column", {
    result <- flag_event(sample_data, "(temperature > 15)")
    expect_equal(
      nrow(result),
      nrow(sample_data)
    )
    expect_equal(
      ncol(result),
      ncol(sample_data) + 1
    )
  })
  
  it("preserves all original columns", {
    result <- flag_event(sample_data, "(temperature > 15)")
    original_cols <- colnames(sample_data)
    expect_true(all(original_cols %in% colnames(result)))
  })
  
})
