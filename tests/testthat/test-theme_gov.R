context("test-theme_gov.R")

# Test the theme_gov function

describe("theme_gov", {
  
  skip_if_not_installed("ggplot2")
  
  it("returns a ggplot2 theme object", {
    theme <- theme_gov()
    expect_is(theme, "theme")
    expect_is(theme, "gg")
  })
  
  it("accepts base_size parameter", {
    theme_small <- theme_gov(base_size = 10)
    theme_large <- theme_gov(base_size = 20)
    
    expect_is(theme_small, "theme")
    expect_is(theme_large, "theme")
  })
  
  it("accepts base_colour parameter", {
    theme_default <- theme_gov(base_colour = "gray40")
    theme_custom <- theme_gov(base_colour = "blue")
    
    expect_is(theme_default, "theme")
    expect_is(theme_custom, "theme")
  })
  
  it("accepts axes parameter with valid options", {
    theme_x <- theme_gov(axes = "x")
    theme_y <- theme_gov(axes = "y")
    theme_xy <- theme_gov(axes = "xy")
    theme_n <- theme_gov(axes = "n")
    
    expect_is(theme_x, "theme")
    expect_is(theme_y, "theme")
    expect_is(theme_xy, "theme")
    expect_is(theme_n, "theme")
  })
  
  it("throws error for invalid axes parameter", {
    expect_error(
      theme_gov(axes = "invalid")
    )
  })
  
  it("can be applied to a ggplot", {
    skip_if_not_installed("ggplot2")
    
    p <- ggplot2::ggplot(data.frame(x = 1:10, y = 1:10)) +
      ggplot2::aes(x = x, y = y) +
      ggplot2::geom_point() +
      theme_gov()
    
    expect_is(p, "ggplot")
  })
  
  it("produces plots without errors for all axis options", {
    skip_if_not_installed("ggplot2")
    
    plot_data <- data.frame(x = 1:10, y = 1:10)
    
    for (axis in c("n", "x", "y", "xy")) {
      p <- ggplot2::ggplot(plot_data) +
        ggplot2::aes(x = x, y = y) +
        ggplot2::geom_point() +
        theme_gov(axes = axis)
      
      expect_is(p, "ggplot")
    }
  })
  
})
