# Theme Tests (test-theme_gov.R)

## Function Overview
`theme_gov()` - ggplot2 theme following government/institutional style guidelines

## Purpose
Provides consistent visual styling for environmental data plots with emphasis on clarity and professionalism.

## Test Cases

### Type Verification
1. **Returns theme object**: Output is valid ggplot2 theme
2. **Proper class**: Inherits from 'theme' and 'gg'
3. **Composable**: Can be added to ggplot objects with `+`

### Parameter Support
1. **base_size**: Controls overall text and element sizes
2. **base_colour**: Specifies axis line color (defaults to "gray40")
3. **axes**: Determines which axes to color

### Axes Parameter Options
1. **axes = "n"**: No colored axes
2. **axes = "x"**: Only x-axis colored
3. **axes = "y"**: Only y-axis colored
4. **axes = "xy"**: Both axes colored
5. **Invalid option**: Throws error for unrecognized values

### Integration with ggplot2
1. **Applies to plots**: Works with ggplot objects
2. **All axis options**: Theme works for all axis configurations
3. **No errors**: Applies without breaking plot generation

## Example Usage

```r
library(ggplot2)
library(adaptNP)

# Basic usage with default settings
plot_data <- data.frame(x = 1:100, y = rnorm(100))

p <- ggplot(plot_data, aes(x = x, y = y)) +
  geom_point() +
  geom_line() +
  theme_gov()

# Customize base size
p <- ggplot(plot_data, aes(x = x, y = y)) +
  geom_point() +
  theme_gov(base_size = 14)

# Custom axis styling
p <- ggplot(plot_data, aes(x = x, y = y)) +
  geom_point() +
  theme_gov(axes = "xy", base_colour = "navy")

# Multiple ggplot elements
p <- ggplot(plot_data, aes(x = x, y = y)) +
  geom_point(color = "steelblue") +
  geom_line(color = "steelblue") +
  labs(title = "Water Quality", x = "Time", y = "Temperature") +
  theme_gov(axes = "xy")
```

## Theme Components

### Default Settings
| Component | Style |
|-----------|-------|
| Legend position | bottom |
| Legend text size | 24 |
| Axis ticks | blank (removed) |
| Grid lines | blank (removed) |
| Panel background | blank/white |
| Facet strip background | blank |
| Facet strip text | bold, black, size + 1 |
| Axis line thickness | Medium |
| Axis line color | Controlled by axes parameter |

### Visual Hierarchy
1. **Primary**: X and Y axes (colored based on parameter)
2. **Secondary**: Axis labels and legend
3. **Tertiary**: Facet labels
4. **Minimal**: Grid lines (removed), ticks (removed)

## Parameter Effects

### base_size
```r
theme_gov(base_size = 12)  # Small text (default: 16)
theme_gov(base_size = 20)  # Large text
```

### base_colour
```r
theme_gov(base_colour = "gray40")   # Default gray
theme_gov(base_colour = "black")    # High contrast
theme_gov(base_colour = "steelblue") # Custom color
```

### axes
```r
theme_gov(axes = "n")   # No colored axes
theme_gov(axes = "x")   # Horizontal axis only
theme_gov(axes = "y")   # Vertical axis only
theme_gov(axes = "xy")  # Both axes (most common)
```

## Best Practices

### Recommended Uses
✓ Environmental monitoring reports
✓ Government/institutional publications
✓ Scientific presentations
✓ Water quality dashboards
✓ Time series plots
✓ Multi-panel comparisons (facet_wrap, facet_grid)

### Not Recommended For
✗ Dense exploratory data analysis
✗ Publication figures requiring heavy grid reference
✗ Complex multi-layer visualizations
✗ Heatmaps or image plots

## Visual Guidelines

### Color Schemes That Work Well
```r
# With theme_gov()
+ scale_color_brewer(palette = "Dark2")
+ scale_fill_brewer(palette = "Set2")
+ scale_color_viridis_c()
```

### Font Sizes
```r
# Adjust for your needs
theme_gov(base_size = 12)  # Presentations/slides
theme_gov(base_size = 14)  # Reports
theme_gov(base_size = 16)  # Default
theme_gov(base_size = 18)  # Large posters
```

## Test Assertions Used
- `expect_is()` - Type checking
- `expect_error()` - Invalid parameter detection
- `expect_true()` / `expect_is(..., "ggplot")` - Integration testing

## Layering with Other Themes

```r
# Can be combined with other ggplot2 theme elements
ggplot(...) +
  geom_point() +
  theme_gov(axes = "xy") +
  theme(plot.title = element_text(face = "bold", size = 20))

# Cannot combine with other base themes
# theme_gov() should be the last theme assignment
```

## Troubleshooting

### Plot Looks Wrong
1. **Ensure ggplot2 loaded**: `library(ggplot2)`
2. **Add theme after other elements**: Last `+ theme_gov()`
3. **Check axes parameter**: Valid values are "n", "x", "y", "xy"

### Colors Not Showing
- Default axis colors are subtle gray
- Try darker base_colour: `base_colour = "black"`
- Check plot background isn't covering axes

### Text Too Small/Large
- Adjust base_size parameter
- Default (16) works for most plots
- Try 14 for dense multi-panel plots, 18 for presentations

## Related Functions
- `theme()` - Base ggplot2 theme function
- `theme_gray()`, `theme_minimal()` - Other ggplot2 themes
- `scale_color_*()` - Color schemes

## Dependencies
- ggplot2 (>= 3.0)
- grid (base R graphics infrastructure)

## Performance Notes
- Theme application is fast (microseconds)
- No computational cost for using vs default theme
- Minimal memory overhead

## Compatibility

### ggplot2 Versions
- Tested with ggplot2 >= 3.0
- Should work with recent versions

### R Versions
- Works with R >= 3.5

## Customization

Create a custom variant:
```r
# Create your own custom function
theme_gov_modified <- function(base_size = 16, base_colour = "navy") {
  theme_gov(base_size = base_size, base_colour = base_colour) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.title = element_text(face = "italic")
  )
}

# Use it
ggplot(...) + geom_point() + theme_gov_modified()
```

## References
- [ggplot2 Themes documentation](https://ggplot2.tidyverse.org/reference/theme.html)
- [Government Design Guidelines](https://www.gov.uk/guidance/content-design)
- [Environmental reporting standards](https://www.environment.gov.uk/)
