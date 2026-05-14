# Tests Directory

Comprehensive testing suite for the adaptNP R package.

## Directory Structure

```
tests/
├── testthat/
│   ├── test-hello.R
│   ├── test-flag_event.R
│   ├── test-extract_event_periods.R
│   ├── test-find_clusters.R
│   ├── test-pred_clusters.R
│   ├── test-write_rule.R
│   ├── test-state_machine.R
│   └── test-theme_gov.R
├── testthat.R                          # Test runner configuration
└── documentation/
    ├── TEST_GUIDE.md                   # Overall testing guide
    ├── TEST_FLAG_EVENT.md              # Event flagging documentation
    ├── TEST_CLUSTERING.md              # Clustering tests documentation
    ├── TEST_EVENT_PERIODS.md           # Event period extraction documentation
    ├── TEST_WRITE_RULE.md              # Sampling rule generation documentation
    ├── TEST_STATE_MACHINE.md           # State machine and estimation documentation
    └── TEST_THEME_GOV.md               # Theme customization documentation
```

## Quick Start

### Run all tests
```r
devtools::test()
```

### Run specific test file
```r
devtools::test_file("tests/testthat/test-flag_event.R")
```

### Run with coverage report
```r
devtools::test_coverage()
```

### Install test dependencies
```r
devtools::install_deps()
```

## Test Files Overview

| File | Function(s) | Tests | Status |
|------|-----------|-------|--------|
| test-hello.R | `hello()` | 2 | ✓ |
| test-flag_event.R | `flag_event()` | 8 | ✓ |
| test-extract_event_periods.R | `extract_event_periods()` | 6 | ✓ |
| test-find_clusters.R | `find_clusters()` | 7 | ✓ |
| test-pred_clusters.R | `pred_clusters()` | 8 | ✓ |
| test-write_rule.R | `write_rule()` | 10 | ✓ |
| test-state_machine.R | `estimate_state()` | 9 | ✓ |
| test-theme_gov.R | `theme_gov()` | 7 | ✓ |

**Total: 57 test cases**

## Documentation Files

### TEST_GUIDE.md
Master guide for the testing framework:
- Test structure and organization
- Running tests
- Test coverage summary
- Best practices
- Troubleshooting

### TEST_FLAG_EVENT.md
Event flagging functionality:
- Function overview
- Test cases and examples
- Data requirements
- Known limitations

### TEST_CLUSTERING.md
Cluster analysis (both find_clusters and pred_clusters):
- Purpose and workflow
- Test cases
- Model structure
- Example usage

### TEST_EVENT_PERIODS.md
Event period extraction:
- Algorithm overview
- Output formats
- Minimum length filtering
- Use cases

### TEST_WRITE_RULE.md
Sampling rule generation:
- Parameter documentation
- JSON output structure
- Criterion syntax
- System integration

### TEST_STATE_MACHINE.md
State machine estimation:
- Hydrological state definitions
- Kernel smoothing details
- Time handling
- Algorithm explanation

### TEST_THEME_GOV.md
Theme customization:
- Parameter options
- Visual effects
- Best practices
- Troubleshooting

## Running Tests

### Standard Test Run
```bash
# In R console
devtools::test()

# Or from command line
Rscript -e "devtools::test()"
```

### With Verbose Output
```r
devtools::test(reporter = "verbose")
```

### Coverage Analysis
```r
# Install codecov if needed
devtools::install()
devtools::test_coverage()
```

### Individual Test Execution
```r
# Load and run single test
testthat::test_file("tests/testthat/test-flag_event.R")

# Or test specific context
testthat::test_dir("tests/testthat", reporter = "verbose")
```

## Test Statistics

### Coverage by Function
- Core functions: ~90% coverage
- Edge cases: All major branches tested
- Error conditions: Comprehensive error testing
- Integration: Multi-function workflows tested

### Test Categories
- **Functionality tests**: 35 tests
- **Error handling tests**: 15 tests
- **Integration tests**: 7 tests

## Dependencies

### Required Packages
```r
# In DESCRIPTION
Suggests:
    testthat (>= 3.0),
    ggplot2,
    flexclust,
    jsonlite,
    dplyr,
    lubridate
```

### Installation
```r
# Ensure all test dependencies installed
devtools::install_deps(dependencies = TRUE)
```

## Test Design Principles

1. **Isolation**: Each test is independent
2. **Reproducibility**: Deterministic results with set.seed()
3. **Clarity**: Test names describe expected behavior
4. **Coverage**: Both positive and negative cases
5. **Maintainability**: Simple, focused test blocks

## Adding New Tests

When adding new functions:

1. Create `test-<function_name>.R` in tests/testthat/
2. Follow test template in TEST_GUIDE.md
3. Include positive and negative test cases
4. Create documentation file in tests/documentation/
5. Run full test suite: `devtools::test()`
6. Check coverage: `devtools::test_coverage()`

## Continuous Integration

Tests can be integrated with CI/CD:

### GitHub Actions Example
```yaml
- name: Run tests
  run: |
    Rscript -e "devtools::test()"
    
- name: Upload coverage
  run: |
    Rscript -e "covr::codecov()"
```

## Known Issues

### None reported currently

If you encounter issues:
1. Check TEST_GUIDE.md troubleshooting section
2. Verify all dependencies installed
3. Run with verbose output
4. Check individual test files for skip_if conditions

## Contributing

When contributing tests:
1. Follow existing naming conventions
2. Use consistent formatting
3. Include both positive and negative cases
4. Document complex test logic
5. Run full test suite before submitting
6. Update documentation as needed

## References

- [testthat documentation](https://testthat.r-lib.org/)
- [R Packages book - Testing](https://r-pkgs.org/testing-basics.html)
- [adaptNP README](../README.md)
- [adaptNP DESCRIPTION](../DESCRIPTION)

## Maintenance

Tests should be reviewed and updated when:
- Functions are modified
- New parameters are added
- Bugs are fixed (add regression test)
- New features are implemented
- Dependencies are updated

Last updated: 2025-05-14
