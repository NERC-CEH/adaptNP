# Event Flagging Tests (test-flag_event.R)

## Function Overview
`flag_event()` - Flags data rows matching user-defined logical criteria

## Purpose
Identifies time periods in a data frame where specified conditions are met.

## Test Cases

### Basic Functionality
1. **Returns event_flag column**: Verifies that the output data frame contains a new `event_flag` logical column
2. **Flags OR criteria**: Tests complex OR conditions like `(temp > 24) | (pH > 7.8)`
3. **Flags AND criteria**: Tests complex AND conditions like `(temp > 20) & (pH > 7.4)`

### Edge Cases
1. **All FALSE results**: Tests criteria that no data meets
2. **Data preservation**: Verifies original columns remain unchanged
3. **Row count**: Confirms output has same number of rows as input

### Error Handling
1. **Non-string criteria**: Tests that passing non-character criteria throws an error
2. **Column naming**: Tests behavior when `event_flag` column already exists

## Example Usage

```r
# Setup
sample_data <- data.frame(
  timestamp = seq.POSIXct(...),
  temperature = c(10, 12, 14, ...),
  pH = c(7.0, 7.1, 7.2, ...)
)

# Test
result <- flag_event(sample_data, "(temperature > 15) & (pH > 7.2)")

# Verify
expect_true("event_flag" %in% colnames(result))
expect_true(any(result$event_flag == TRUE))
```

## Data Requirements
- Input: Data frame with numeric or date columns
- Criteria: Character string with R-style logical expressions
- Output: Data frame with additional boolean `event_flag` column

## Known Limitations
- Criteria must be valid R expressions
- Column names are case-sensitive
- Timestamp column not required (any columns can be used)

## Related Functions
- `extract_event_periods()` - Extracts time ranges of flagged events
- Other filtering functions from dplyr

## Test Assertions Used
- `expect_true()` - Boolean checks
- `expect_equal()` - Equality comparisons
- `expect_error()` - Error verification
- `expect_in()` - Membership checks
