context("test-write_rule.R")

# Test the write_rule function

describe("write_rule", {
  
  it("returns a character string (JSON)", {
    result <- write_rule(
      id = 1,
      name = "Test Rule",
      criterion = "(temp > 20) | (pH < 7)",
      samplingFrequency = "PT10M"
    )
    
    expect_is(result, "character")
  })
  
  it("produces valid JSON", {
    result <- write_rule(
      id = 1,
      name = "Test Rule",
      criterion = "(temp > 20)",
      samplingFrequency = "PT10M"
    )
    
    # Should be parseable as JSON
    expect_true(
      !is.null(jsonlite::fromJSON(result))
    )
  })
  
  it("includes all specified parameters in JSON output", {
    result <- write_rule(
      id = 1,
      name = "High Temperature Alert",
      comment = "Sample high temperature conditions",
      criterion = "(temperature > 25)",
      determinants = c("temperature", "pH"),
      samplingFrequency = "PT15M"
    )
    
    json_obj <- jsonlite::fromJSON(result)
    
    expect_equal(json_obj$id, 1)
    expect_equal(json_obj$name, "High Temperature Alert")
    expect_equal(json_obj$comment, "Sample high temperature conditions")
    expect_equal(json_obj$criterion, "(temperature > 25)")
    expect_equal(json_obj$samplingFrequency, "PT15M")
  })
  
  it("handles NULL values appropriately", {
    result <- write_rule(
      id = NULL,
      name = NULL,
      criterion = "(temp > 15)",
      samplingFrequency = "PT5M"
    )
    
    json_obj <- jsonlite::fromJSON(result)
    expect_true(is.null(json_obj$id) || json_obj$id == "null")
  })
  
  it("sets disabled to FALSE by default", {
    result <- write_rule(
      criterion = "(temp > 20)",
      samplingFrequency = "PT10M"
    )
    
    json_obj <- jsonlite::fromJSON(result)
    expect_false(json_obj$disabled)
  })
  
  it("respects the disabled parameter", {
    result_disabled <- write_rule(
      disabled = TRUE,
      criterion = "(temp > 20)",
      samplingFrequency = "PT10M"
    )
    
    json_obj <- jsonlite::fromJSON(result_disabled)
    expect_true(json_obj$disabled)
  })
  
  it("defaults criterionType to 'query_R'", {
    result <- write_rule(
      criterion = "(temp > 20)",
      samplingFrequency = "PT10M"
    )
    
    json_obj <- jsonlite::fromJSON(result)
    expect_equal(json_obj$criterionType, "query_R")
  })
  
  it("supports determinants as string 'ALL' or vector", {
    result_all <- write_rule(
      criterion = "(temp > 20)",
      determinants = "ALL",
      samplingFrequency = "PT10M"
    )
    
    result_specific <- write_rule(
      criterion = "(temp > 20)",
      determinants = c("temperature", "pH"),
      samplingFrequency = "PT10M"
    )
    
    json_all <- jsonlite::fromJSON(result_all)
    json_specific <- jsonlite::fromJSON(result_specific)
    
    expect_equal(json_all$determinants, "ALL")
    expect_true(length(json_specific$determinants) > 0)
  })
  
  it("produces prettified output", {
    result <- write_rule(
      criterion = "(temp > 20)",
      samplingFrequency = "PT10M"
    )
    
    # Should contain newlines and indentation
    expect_true(grepl("\n", result))
  })
  
})
