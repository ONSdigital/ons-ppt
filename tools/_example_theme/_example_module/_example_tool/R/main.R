# Example Adder Tool
# Description: Adds two numbers together and prints the result.

library(roxygen2)

#' Adds two numbers together.
#'
#' @param x First number (numeric)
#' @param y Second number (numeric)
#' @return The sum of x and y (numeric)
#' @examples
#' example_add_numbers(2, 3)
#' # [1] 5
example_add_numbers <- function(x, y) {
  x + y
}

# Example usage
print(example_add_numbers(2, 3))
