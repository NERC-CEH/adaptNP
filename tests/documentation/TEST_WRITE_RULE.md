# Sampling Rule Tests (test-write_rule.R)

## Function Overview
`write_rule()` - Creates adaptive sampling rule specifications in JSON format

## Purpose
Generates machine-readable configuration for adaptive sensor sampling systems.

## Test Cases

### JSON Format
1. **Valid JSON output**: Returns properly formatted JSON string
2. **Parseable**: Can be parsed by jsonlite::fromJSON()
3. **Prettified**: Output includes formatting for readability

### Parameter Inclusion
1. **All parameters included**: Every specified parameter appears in JSON
2. **Parameter values preserved**: Values match input exactly
3. **Null handling**: NULL inputs handled appropriately

### Default Values
1. **disabled defaults to FALSE**: Rules active by default
2. **criterionType defaults to 'query_R'**: Uses R expression format
3. **determinants defaults to 'ALL'**: Applies to all sensors by default

### Parameter Variations
1. **determinants as string**: Accepts 'ALL' for global application
2. **determinants as vector**: Accepts vector of specific variable names
3. **disabled TRUE/FALSE**: Respects both states

### ISO 8601 Duration Support
1. **Standard formats**: PT10M, PT1H, P1D work correctly
2. **Various frequencies**: Supports minute, hour, day, month intervals

## Example Usage

```r
# Simple rule
json_rule <- write_rule(
  criterion = "(temperature > 25)",
  samplingFrequency = "PT10M"
)

# Complex rule with all parameters
json_rule <- write_rule(
  id = 1,
  name = "High Temperature Alert",
  comment = "Increases sampling when temperature exceeds 25°C",
  criterion = "(temperature > 25) | (DO < 5)",
  determinants = c("temperature", "DO"),
  samplingFrequency = "PT5M"
)

cat(json_rule)
```

## Output Structure

```json
{
  "id": 1,
  "name": "High Temperature Alert",
  "comment": "Descriptive text",
  "disabled": false,
  "criterionType": "query_R",
  "criterionOptArg": null,
  "criterion": "(temperature > 25)",
  "determinants": ["temperature", "pH"],
  "samplingFrequency": "PT10M"
}
```

## Parameter Descriptions

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| id | numeric | Unique rule identifier | 1 |
| name | character | Human-readable rule name | "High Temp Alert" |
| comment | character | Detailed description | "When temp > 25" |
| disabled | logical | Rule active (FALSE) or inactive (TRUE) | FALSE |
| criterionType | character | Evaluation method | "query_R" |
| criterionOptArg | character | Optional criterion arguments | NULL |
| criterion | character | R-style logical expression | "(temp > 20)" |
| determinants | character/vector | Variables rule applies to | "ALL" or c("temp", "pH") |
| samplingFrequency | character | ISO 8601 duration format | "PT10M" |

## Criterion Syntax

Valid R expressions for adaptive sampling:

```r
# Temperature only
"(temperature > 25)"

# Multiple parameters
"(temperature > 25) | (pH < 7.0)"

# Complex logic
"((temperature > 20) & (pH > 7)) | (DO < 5)"

# Numeric comparisons
"(value > threshold) | (value < minimum)"

# Range checking
"(value > min) & (value < max)"
```

## Data Requirements
- criterion: Non-empty character string with valid R syntax
- samplingFrequency: ISO 8601 duration format
- determinants: Either "ALL" or vector of variable names
- All other parameters: Optional or have sensible defaults

## Known Limitations
- No validation of criterion syntax (deferred to runtime)
- No validation of ISO 8601 duration format
- Does not check if variables exist in actual data
- Cannot test rule effectiveness at design time

## System Integration

### Typical Workflow
1. **Design rule** → write_rule() → JSON
2. **Store rule** → Database/Config File
3. **Parse rule** → System reads JSON
4. **Evaluate rule** → Runtime criterion evaluation
5. **Execute action** → Sampling adjustment

### System Requirements
- JSON parser
- R expression evaluator
- ISO 8601 duration parser
- Sensor/sampling scheduler

## Test Assertions Used
- `expect_is()` - Type checking
- `expect_equal()` - Value verification
- `expect_true()`/`expect_false()` - Boolean checks
- `expect_true(!is.null())` - JSON validity

## Related Functions
- `flag_event()` - Criterion evaluation at runtime
- `extract_event_periods()` - Event analysis

## References
- [ISO 8601 Duration Format](https://en.wikipedia.org/wiki/ISO_8601#Durations)
- [JSON Specification](https://www.json.org/)
- [jsonlite R package](https://cran.r-project.org/web/packages/jsonlite/)

## Performance Notes
- Fast JSON generation: microseconds per rule
- Suitable for real-time rule updates
- Minimal memory footprint
