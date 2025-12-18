

#' Write a sampling rule in JSON format
#'
#' @param id A number. (optional)
#' @param name A string. (optional)
#' @param comment A string. (optional)
#' @param disabled TRUE or FALSE
#' @param criterionType 'query_R' (default)
#' @param criterionOptArg A string. (optional)
#' @param criterion A string.
#' @param determinants "ALL" or a vector string
#' @param samplingFrequency A string in ISO8601 duration format (see https://docs.digi.com/resources/documentation/digidocs/90001488-13/reference/r_iso_8601_duration_format.htm).
#'
#' @return A JSON file contain key-value pairs of a sampling rule.
#' @export
#'
#' @examples
#' query = '(Sonde1_Temperature > 15) | (Sonde1_pH >7)'
#' write_rule(criterion = query,samplingFrequency = 'P1M')
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


check_rule <-function(input){


}
