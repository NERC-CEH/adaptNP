#' Create a sampling rule in JSON format
#'
#' Constructs a sampling rule specification and returns it as a formatted
#' JSON string. This is typically used to define when and how sensors or
#' monitoring systems should collect data based on conditional logic.
#'
#' @param id Optional numeric identifier for the rule.
#' @param name Optional name of the rule (character string).
#' @param comment Optional descriptive comment (character string).
#' @param disabled Logical. If `TRUE`, the rule is inactive. Default is `FALSE`.
#' @param criterionType Character string specifying the rule evaluation type.
#'   Default is `"query_R"`.
#' @param criterionOptArg Optional character string providing additional
#'   arguments for the criterion evaluation.
#' @param criterion Character string defining the rule condition. Typically
#'   an R-style logical expression (e.g. `"(temp > 15) | (pH > 7)"`).
#' @param determinants Either `"ALL"` or a character vector specifying
#'   which variables (e.g. sensor names) the rule applies to.
#' @param samplingFrequency Character string specifying the sampling interval
#'   in ISO 8601 duration format (e.g. `"PT10M"` for 10 minutes, `"P1D"` for 1 day).
#'
#' @return A formatted JSON string representing the sampling rule, with
#'   key-value pairs corresponding to the input arguments.
#'
#' @details
#' The `criterion` defines the condition under which the sampling rule is triggered.
#' It is evaluated according to the specified `criterionType` (default `"query_R"`).
#'
#' The `samplingFrequency` must follow ISO 8601 duration conventions. For example:
#' \itemize{
#'   \item `"PT1H"` = 1 hour
#'   \item `"PT30M"` = 30 minutes
#'   \item `"P1D"` = 1 day
#'   \item `"P1M"` = 1 month
#' }
#'
#' This function does not validate the correctness of the logical expression
#' or duration format; users should ensure inputs are valid for the target system.
#'
#' @examples
#' # Define a sampling rule triggered by temperature or pH
#' query <- "(Sonde1_Temperature > 15) | (Sonde1_pH > 7)"
#'
#' json_rule <- write_rule(
#'   id = 1,
#'   name = "High variability sampling",
#'   criterion = query,
#'   determinants = c("Sonde1_Temperature", "Sonde1_pH"),
#'   samplingFrequency = "PT10M"
#' )
#'
#' cat(json_rule)
#'
#' @seealso \code{\link[jsonlite]{toJSON}}
#'
#' @export
write_rule <-function(id = NULL,
                               name = NULL,
                               comment = NULL,
                               disabled = FALSE,
                               criterionType='query_R',
                               criterionOptArg = NULL,
                               criterion,
                               determinants = "ALL",
                               samplingFrequency
){
  list("id" = id,
      "name" = name,
      "comment"=comment,
      "disabled" = disabled,
      "criterionType"= criterionType,
      "criterionOptArg" = criterionOptArg,
      "criterion" = criterion,
      "determinants" = determinants,
      "samplingFrequency" = samplingFrequency) %>%
  jsonlite::toJSON(auto_unbox = TRUE) %>%
  jsonlite::prettify()
}


# check_rule <-function(input){


# }
