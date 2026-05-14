context("test-hello.R")

# Test the hello function

describe("hello", {
  
  it("returns NULL invisibly", {
    result <- hello()
    expect_null(result)
  })
  
  it("prints 'Hello, world!' to console", {
    expect_output(hello(), "Hello, world!")
  })
  
})
