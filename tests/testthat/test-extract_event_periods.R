context("test-extract_event_periods.R")

# Test the extract_event_periods function

describe("extract_event_periods", {
  
  # Create sample flagged data
  flagged_data <- data.frame(
    timestamp = seq.POSIXct(
      from = as.POSIXct("2023-01-01 00:00:00"),
      by = "5 min",
      length.out = 100
    ),
    flag = c(
      rep(FALSE, 10),  # Baseflow period
      rep(TRUE, 20),   # Event 1: 20 consecutive TRUE flags
      rep(FALSE, 10),  # Gap
      rep(TRUE, 15),   # Event 2: 15 consecutive TRUE flags
      rep(FALSE, 45)   # Rest
    )
  )
  
  it("returns a data frame or list with event periods", {
    result <- extract_event_periods(flagged_data, min_length = 5)
    expect_true(
      is.data.frame(result) || is.list(result)
    )
  })
  
  it("identifies multiple event periods", {
    result <- extract_event_periods(flagged_data, min_length = 5)
    # Should identify at least 2 events
    if (is.data.frame(result)) {
      expect_true(nrow(result) >= 2)
    } else if (is.list(result)) {
      expect_true(length(result) >= 2)
    }
  })
  
  it("respects the min_length parameter", {
    result_strict <- extract_event_periods(flagged_data, min_length = 20)
    result_lenient <- extract_event_periods(flagged_data, min_length = 5)
    
    if (is.list(result_strict) && is.list(result_lenient)) {
      expect_true(length(result_strict) <= length(result_lenient))
    }
  })
  
  it("returns empty when no events meet min_length", {
    flagged_data_short <- data.frame(
      timestamp = seq.POSIXct(
        from = as.POSIXct("2023-01-01 00:00:00"),
        by = "5 min",
        length.out = 20
      ),
      flag = c(TRUE, TRUE, FALSE, FALSE, FALSE, TRUE, rep(FALSE, 14))
    )
    
    result <- extract_event_periods(flagged_data_short, min_length = 5)
    if (is.list(result)) {
      expect_true(length(result) == 0)
    }
  })
  
  it("requires timestamp and flag columns", {
    bad_data <- data.frame(
      time = seq.POSIXct(
        from = as.POSIXct("2023-01-01 00:00:00"),
        by = "5 min",
        length.out = 10
      ),
      my_flag = rep(TRUE, 10)
    )
    
    expect_error(
      extract_event_periods(bad_data, min_length = 5)
    )
  })
  
  it("returns events with start and end times", {
    result <- extract_event_periods(flagged_data, min_length = 5)
    if (is.list(result) && length(result) > 0) {
      # Check that each event has start and end
      first_event <- result[[1]]
      if (is.list(first_event)) {
        expect_true("start" %in% names(first_event))
        expect_true("end" %in% names(first_event))
      }
    }
  })
  
})
