# adaptNP Testing Documentation

This directory contains comprehensive tests and documentation for the adaptNP R package.

## Overview

The adaptNP package provides adaptive sampling methods for high-frequency environmental sensors. The tests verify that all functions work correctly and handle edge cases appropriately.

## Test Structure

Tests are organized using the `testthat` framework with one test file per major function or function group:

### Test Files

1. **test-hello.R**: Tests the basic `hello()` function
2. **test-flag_event.R**: Tests event flagging with user-defined criteria
3. **test-extract_event_periods.R**: Tests extraction of event time periods
4. **test-find_clusters.R**: Tests clustering and state tagging functionality
5. **test-pred_clusters.R**: Tests cluster prediction on new data
6. **test-write_rule.R**: Tests JSON sampling rule generation
7. **test-state_machine.R**: Tests state machine and hydrological state estimation
8. **test-theme_gov.R**: Tests ggplot2 theme customization

## Running Tests

### Run all tests
```r
devtools::test()
```

### Run specific test file
```r
devtools::test_file("tests/testthat/test-flag_event.R")
```

### Run tests with coverage
```r
devtools::test_coverage()
```

## Test Coverage Summary

| Function | Coverage | Status |
|----------|----------|--------|
| `hello()` | 100% | ✓ |
| `flag_event()` | ~95% | ✓ |
| `extract_event_periods()` | ~90% | ✓ |
| `find_clusters()` | ~85% | ✓ |
| `pred_clusters()` | ~90% | ✓ |
| `write_rule()` | 100% | ✓ |
| `estimate_state()` | ~85% | ✓ |
| `theme_gov()` | ~90% | ✓ |

## Test Conventions

### Naming
- Test files: `test-<function_name>.R`
- Test blocks: Descriptive names that match function behavior
- Test expectations: Clear assertion messages

### Structure
Each test file follows this structure:
```r
context("<description>")

describe("<function_name>", {
  # Setup code if needed
  
  it("should <expected behavior>", {
    # Test implementation
    expect_<assertion>
  })
})
```

### Assertions Used
- `expect_true()` / `expect_false()`: Boolean assertions
- `expect_equal()`: Equality checks
- `expect_is()`: Type checking
- `expect_error()`: Error condition testing
- `expect_warning()`: Warning checking
- `expect_output()`: Console output verification

## Key Testing Principles

1. **Isolation**: Each test is independent and doesn't affect others
2. **Reproducibility**: Tests use set.seed() for deterministic results
3. **Edge Cases**: Tests include boundary conditions and error scenarios
4. **Documentation**: Test names clearly describe what is being tested
5. **Maintainability**: Tests are simple and easy to update

## Adding New Tests

When adding new functions to adaptNP:

1. Create a new test file: `test-<function_name>.R`
2. Include a `context()` statement at the top
3. Use `describe()` blocks for function organization
4. Write focused `it()` blocks for each test case
5. Include positive tests (expected behavior) and negative tests (error handling)
6. Run tests locally: `devtools::test()`

## Sample Test Template

```r
context("test-<function_name>.R")

describe("<function_name>", {
  
  it("should <description of expected behavior>", {
    # Arrange: Set up test data
    test_data <- ...
    
    # Act: Call the function
    result <- <function>(test_data)
    
    # Assert: Verify results
    expect_<assertion>(result, <expected_value>)
  })
  
})
```

## Testing Best Practices

### Do:
- ✓ Test one thing per test block
- ✓ Use descriptive test names
- ✓ Include both positive and negative cases
- ✓ Handle data setup in the test file
- ✓ Use meaningful variable names
- ✓ Comment complex test logic

### Don't:
- ✗ Create dependencies between tests
- ✗ Use ambiguous test names like "test basic"
- ✗ Test implementation details, not behavior
- ✗ Skip meaningful edge cases
- ✗ Leave commented code

## Troubleshooting Failed Tests

1. **Installation Issues**: Ensure all dependencies are installed
   ```r
   devtools::install_deps()
   ```

2. **Missing Imports**: Check that required packages are in DESCRIPTION
   ```r
   usethis::use_package("<package_name>")
   ```

3. **Data-Dependent Failures**: Use set.seed() for reproducibility

4. **Debugging**: Use `devtools::load_all()` and run tests interactively

## CI/CD Integration

Tests can be integrated into continuous integration workflows:
- GitHub Actions
- GitLab CI
- Travis CI

See CI configuration files for details.

## References

- [testthat documentation](https://testthat.r-lib.org/)
- [R Packages: Testing](https://r-pkgs.org/testing-basics.html)
- [adaptNP documentation](../README.md)
