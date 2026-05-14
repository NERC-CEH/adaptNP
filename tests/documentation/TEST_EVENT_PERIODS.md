# Event Period Extraction Tests (test-extract_event_periods.R)

## Function Overview
`extract_event_periods()` - Identifies and extracts time ranges of consecutive flagged events

## Purpose
Converts boolean event flags into structured time period data (start/end timestamps).

## Test Cases

### Basic Functionality
1. **Returns data structure**: Output should be data frame or list of events
2. **Identifies multiple events**: Detects separate event periods correctly
3. **Includes timestamps**: Returns start and end times for each event

### Minimum Length Parameter
1. **Respects min_length**: Events shorter than threshold are excluded
2. **Flexible filtering**: Can adjust sensitivity with different min_length values
3. **Example**: min_length=5 captures more events than min_length=20

### Data Validation
1. **Requires timestamp column**: Must have column named `timestamp`
2. **Requires flag column**: Must have column named `flag`
3. **Proper sorting**: Sorts data by timestamp before processing

### Edge Cases
1. **No events**: Returns empty list when no events meet criteria
2. **Single event**: Handles data with only one event period
3. **Continuous event**: Handles entire dataset as one event

## Example Usage

```r
# Setup flagged data
flagged_data <- data.frame(
  timestamp = seq.POSIXct(
    from = as.POSIXct("2023-01-01"),
    by = "5 min",
    length.out = 100
  ),
  flag = c(
    rep(FALSE, 10),  # Baseflow
    rep(TRUE, 20),   # Event 1
    rep(FALSE, 10),  # Gap
    rep(TRUE, 15),   # Event 2
    rep(FALSE, 45)   # Rest
  )
)

# Extract periods
result <- extract_event_periods(flagged_data, min_length = 5)

# Result structure
# Events with consecutive TRUE flags, at least 5 observations each
```

## Output Format

### List Format
```r
list(
  list(start = POSIXct, end = POSIXct),
  list(start = POSIXct, end = POSIXct),
  ...
)
```

### Data Frame Format
```r
data.frame(
  start = c(POSIXct, POSIXct, ...),
  end = c(POSIXct, POSIXct, ...)
)
```

## Data Requirements

### Input
- Data frame with `timestamp` column (POSIXct format)
- Data frame with `flag` column (logical: TRUE/FALSE)
- Optional: `min_length` parameter (default = 10)

### Output
- List or data frame of event periods
- Each event has start and end times
- Empty if no events meet minimum length

## Algorithm

1. Sort data by timestamp
2. Identify consecutive TRUE flags
3. Calculate event length
4. Filter events by min_length
5. Extract start/end times for qualifying events
6. Return structured results

## Known Limitations

- Flag column must be named exactly `flag`
- Timestamp column must be named exactly `timestamp`
- Requires POSIXct or numeric timestamp format
- Minimum length based on number of observations, not duration

## Related Functions
- `flag_event()` - Creates the flag column
- Sequential event detection workflow

## Test Assertions Used
- `expect_true()` - Existence checks
- `expect_equal()` - Count verification
- `expect_error()` - Error conditions
- `expect_null()` / `expect_true()` - Empty result checking

## Use Cases

1. **Storm event detection**: Identify precipitation or high flow periods
2. **Water quality alerts**: Find periods where thresholds exceeded
3. **Sensor anomalies**: Detect systematic measurement problems
4. **Maintenance scheduling**: Identify equipment issues by event clustering
5. **Adaptive sampling**: Determine when to increase sampling frequency

## Performance Notes

- O(n) time complexity where n = number of observations
- Memory efficient: processes streaming data possible
- Fast for typical environmental monitoring datasets (thousands of records)
