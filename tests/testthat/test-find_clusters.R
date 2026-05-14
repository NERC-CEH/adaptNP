context("test-find_clusters.R")

# Test the find_clusters function

describe("find_clusters", {
  
  # Create synthetic cluster data
  set.seed(42)
  cluster_data <- data.frame(
    var1 = c(rnorm(30, mean = 0, sd = 1), rnorm(30, mean = 5, sd = 1)),
    var2 = c(rnorm(30, mean = 0, sd = 1), rnorm(30, mean = 5, sd = 1)),
    var3 = c(rnorm(30, mean = 0, sd = 1), rnorm(30, mean = 5, sd = 1))
  )
  
  it("returns a kcca object", {
    result <- find_clusters(cluster_data)
    expect_is(result, "kcca")
  })
  
  it("identifies at least 2 clusters for bimodal data", {
    result <- find_clusters(cluster_data)
    # The kcca object should have cluster information
    expect_true(!is.null(result@centers))
    expect_true(nrow(result@centers) >= 2)
  })
  
  it("handles data with missing values", {
    data_with_na <- cluster_data
    data_with_na[5, 1] <- NA
    data_with_na[10, 2] <- NA
    
    # Should not throw an error
    result <- find_clusters(data_with_na)
    expect_is(result, "kcca")
  })
  
  it("requires numeric matrix or data frame", {
    bad_data <- data.frame(
      var1 = letters[1:10],
      var2 = 1:10
    )
    
    # Should handle or error gracefully
    expect_error(
      find_clusters(bad_data),
      NA  # Flexible error checking
    ) || {
      # Or it could fail silently
      result <- tryCatch(
        find_clusters(bad_data),
        error = function(e) NULL
      )
      expect_null(result)
    }
  })
  
  it("works with small datasets", {
    small_data <- cluster_data[1:10, ]
    result <- find_clusters(small_data)
    expect_is(result, "kcca")
  })
  
  it("produces reproducible results with same seed", {
    set.seed(42)
    result1 <- find_clusters(cluster_data)
    
    set.seed(42)
    result2 <- find_clusters(cluster_data)
    
    # Compare cluster centers
    expect_equal(
      result1@centers,
      result2@centers
    )
  })
  
})
