# State Machine Tests (test-state_machine.R)

## Function Overview

### estimate_state()
Estimates hydrological state and derivatives from time series data using kernel smoothing.

### update_state()
State machine logic for transitioning between hydrological event states (Wong & Kerkez 2016).

## estimate_state() Tests

### Purpose
Transforms noisy time series data into smoothed values and their derivatives for state classification.

### Test Cases

#### Output Structure
1. **Returns list**: Four named components returned
2. **Correct components**: Includes time_numeric, x, dx, ddx
3. **Correct lengths**: All output vectors match input length

#### Time Handling
1. **POSIXct input**: Handles date-time objects
2. **Numeric input**: Accepts raw numeric time values
3. **Auto unit detection**: "auto" mode selects appropriate units
4. **Explicit units**: Supports secs, mins, hours, days, weeks

#### Derivative Units
1. **per_second**: Default derivative scaling
2. **per_minute**: Scaled to changes per minute

#### Error Handling
1. **Invalid time type**: Non-POSIXct, non-numeric time errors
2. **Invalid units**: Unrecognized time/derivative units rejected

#### Data Processing
1. **Missing values**: Handles NA values gracefully
2. **Kernel smoothing**: Output is smoother than input
3. **Variance reduction**: Smoothed variance < original variance

## State Machine Workflow

### States (Wong & Kerkez 2016)
```
BASEFLOW
    ↓
ONSET (high derivative, high magnitude)
    ↓
RISING_INFLECTION (peak derivatives)
    ↓
PEAK (zero/low derivative)
    ↓
FALLING_INFLECTION (negative derivatives)
    ↓
RETURN_TO_BASEFLOW (back to baseline)
    ↓
BASEFLOW
```

### State Transitions
- **BASEFLOW → ONSET**: High slope threshold exceeded
- **ONSET → RISING_INFLECTION**: Second derivative positive
- **RISING_INFLECTION → PEAK**: First derivative near zero
- **PEAK → FALLING_INFLECTION**: Second derivative negative
- **FALLING_INFLECTION → RETURN_TO_BASEFLOW**: Flow near baseline
- **RETURN_TO_BASEFLOW → BASEFLOW**: Remain stable

## Example Usage

```r
# Generate synthetic discharge data
time <- seq.POSIXct(
  from = as.POSIXct("2023-01-01"),
  by = "1 hour",
  length.out = 100
)

# Simulate storm event: baseflow → rise → peak → decline → baseflow
y <- c(
  rep(10, 20),  # Baseflow
  seq(10, 30, length.out = 20),  # Rising
  seq(30, 25, length.out = 20),  # Peak
  seq(25, 10, length.out = 40)   # Return to baseflow
)

# Estimate state
result <- estimate_state(time, y, kernel_l = 60)

# Access components
smoothed <- result$x        # Smoothed values
dQ <- result$dx            # First derivative (rate of change)
ddQ <- result$ddx          # Second derivative (acceleration)
```

## Kernel Smoothing Parameters

### kernel_l (kernel length)
- Default: 60 (time units)
- Larger values: More smoothing, slower transitions
- Smaller values: Less smoothing, sharper features

### Effect on Derivatives
```
kernel_l = 10  → Sharp derivatives, noisy
kernel_l = 60  → Moderate smoothing (default)
kernel_l = 120 → Heavy smoothing, slow changes
```

## Data Requirements

### Input
- time: POSIXct/POSIXlt or numeric vector
- y: Numeric vector of measurements
- Same length required

### Output
```r
list(
  time_numeric = numeric,  # Time in specified units
  x = numeric,            # Smoothed values
  dx = numeric,           # First derivative
  ddx = numeric           # Second derivative
)
```

### Time Units
| Unit | Usage |
|------|-------|
| secs | Sub-minute resolution |
| mins | Typical monitoring data |
| hours | Low-frequency sampling |
| days | Long-term trends |
| weeks | Very low resolution |

## Limitations

1. **Window size**: Fixed kernel window (i±10 points)
2. **Edge effects**: Derivatives at boundaries less reliable
3. **Missing data**: Only local interpolation, not global
4. **First observation**: dx[1] is NA
5. **Second observation**: ddx[1:2] are NA

## Algorithm Details

### Gaussian Kernel
```
w[i] = exp(-0.5 * ((t[idx] - t[i]) / kernel_l)^2)
x_hat[i] = sum(w * y[idx]) / sum(w)
```

### Derivative Estimation
```
dx[i] = (x_hat[i+1] - x_hat[i]) / (t[i+1] - t[i])
ddx[i] = (dx[i+1] - dx[i]) / (t[i+1] - t[i])
```

## Test Assertions Used
- `expect_is()` - Type verification
- `expect_equal()` - Length checks
- `expect_error()` - Error condition testing
- `expect_true()` - Logical assertions

## Related Functions
- `update_state()` - State transitions
- `run_state_machine()` - Full state sequence
- `plot_state_machine()` - Visualization

## Scientific References

1. **Wong & Kerkez (2016)**
   - "Adaptive flood sampling for water quality"
   - Water Resources Research
   - DOI: Relevant to storm event detection

2. **Kernel Smoothing**
   - Gaussian weighted averaging
   - Local polynomial approximation
   - Smoothness vs bias trade-off

## Performance Notes

- Time complexity: O(n²) with 20-point window
- Can optimize with compiled code (e.g., C++)
- Suitable for real-time processing of high-frequency data
- Memory: O(n) for input and output

## Debugging Tips

1. **Check time ordering**: Data must be sorted by time
2. **Verify units**: Ensure consistent time units
3. **Inspect NA values**: Missing data can affect derivatives
4. **Adjust kernel_l**: May need tuning for your data
5. **Compare outputs**: Plot to visualize smoothing effect
