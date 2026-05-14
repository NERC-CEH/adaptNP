# Cluster Analysis Tests (test-find_clusters.R, test-pred_clusters.R)

## Function Overview

### find_clusters()
Automatically identifies optimal number of clusters using elbow method with k-means clustering.

### pred_clusters()
Predicts cluster membership for new data using a previously fitted clustering model.

## find_clusters() Tests

### Purpose
Determines natural groupings in multivariate data for state tagging.

### Test Cases

#### Basic Functionality
1. **Returns kcca object**: Output should be a kcca (k-centers cluster algorithm) object
2. **Identifies multiple clusters**: Bimodal data should detect at least 2 clusters
3. **Produces reproducible results**: Same seed should give identical results

#### Data Handling
1. **Handles missing values**: NA values should be handled gracefully
2. **Works with small datasets**: Should function with 10+ observations
3. **Requires numeric data**: Non-numeric columns should error or be handled

#### Algorithm
1. **Elbow method**: Automatically selects k where improvement drops below 25%
2. **Scaling**: Data should be scaled before clustering
3. **Reproducibility**: Uses set.seed(200) internally

## pred_clusters() Tests

### Purpose
Applies trained clustering model to new observations.

### Test Cases

#### Basic Functionality
1. **Adds state column**: Output includes predicted cluster labels
2. **Preserves data**: Original columns remain intact
3. **Correct row count**: Output has same number of rows as input

#### Predictions
1. **Numeric states**: Predictions are numeric cluster IDs
2. **No missing predictions**: All rows receive a state label
3. **Valid states**: States fall within trained cluster range

#### Error Handling
1. **Missing columns**: Errors when required training variables are absent
2. **Column mismatch**: Stops if input lacks variables used in training

#### Options
1. **option = "same"**: Direct prediction for each row
2. **option = "daily"**: Not fully tested (incomplete implementation)

## Example Usage

```r
# Training
set.seed(42)
train_data <- data.frame(
  var1 = c(rnorm(30, 0, 1), rnorm(30, 5, 1)),
  var2 = c(rnorm(30, 0, 1), rnorm(30, 5, 1))
)

model <- find_clusters(train_data)

# Prediction
test_data <- data.frame(
  var1 = rnorm(10, 0, 1),
  var2 = rnorm(10, 0, 1)
)

result <- pred_clusters(model, test_data, option = "same")
```

## Data Requirements

### find_clusters()
- Numeric matrix or data frame
- Multiple continuous variables
- Minimum ~10 observations recommended
- Can contain NA values

### pred_clusters()
- Test data must have all training variables
- Variable names must match exactly
- Numeric columns expected

## Model Object Structure

The returned `kcca` object contains:
- `@centers`: Cluster centroids (numeric matrix)
- `@cluster`: Assignment of training data to clusters
- `@xrange`: Feature ranges used for scaling
- `@call`: Function call used to create model

## State Tagging Workflow

```
1. Historical Data → find_clusters() → Cluster Model
                                            ↓
2. New Observations → pred_clusters() → Predicted States
```

## Limitations

- Cannot predict states outside training data range
- Assumes similar data distributions
- Scaling is data-dependent
- Limited to numeric variables

## Related Functions
- `estimate_state()` - State machine hydrological modeling
- `flag_event()` - Event detection (alternative approach)

## References
- Wong & Kerkez (2016) - Storm event state machine
- k-means clustering algorithm
