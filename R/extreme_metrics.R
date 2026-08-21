#' Extreme Recall
#'
#' Computes the proportion of observations exceeding a specified
#' percentile threshold that were retained in the sampled dataset.
#'
#' Extreme Recall quantifies the ability of a sampling strategy to
#' capture observations in the upper tail of the distribution.
#'
#' @param full_values Numeric vector containing the complete time series.
#' @param sampled_mask Logical vector indicating sampled observations.
#' Must have the same length as `full_values`.
#' @param percentile Percentile threshold used to define extreme
#' observations. Default is 0.99 (P99).
#' @param inclusive Logical indicating whether values equal to the
#' threshold should be counted as extreme. Default is `FALSE`.
#'
#' @return Numeric value between 0 and 1.
#'
#' @examples
#' x <- rnorm(1000)
#' mask <- runif(1000) < 0.1
#'
#' extreme_recall(x, mask)
#' extreme_recall(x, mask, percentile = 0.95)
#'
#' @export
extreme_recall <- function(
  full_values,
  sampled_mask,
  percentile = 0.99,
  inclusive = FALSE
) {

  stopifnot(
    length(full_values) == length(sampled_mask),
    is.logical(sampled_mask)
  )

  threshold <- stats::quantile(
    full_values,
    probs = percentile,
    na.rm = TRUE
  )

  extreme_mask <- if (inclusive) {
    full_values >= threshold
  } else {
    full_values > threshold
  }

  n_extreme <- sum(extreme_mask, na.rm = TRUE)

  if (n_extreme == 0) {
    return(NA_real_)
  }

  sum(extreme_mask & sampled_mask, na.rm = TRUE) /
    n_extreme
}

#' Oversampling Factor
#'
#' Computes the enrichment of extreme observations in the sampled
#' dataset relative to the overall sampling frequency.
#'
#' Values greater than one indicate preferential sampling of
#' extreme observations. A value of one corresponds to uniform
#' random sampling.
#'
#' @param full_values Numeric vector containing the complete time series.
#' @param sampled_mask Logical vector indicating sampled observations.
#' @param percentile Percentile threshold used to define extremes.
#' Default is 0.99 (P99).
#'
#' @return Numeric value greater than or equal to zero.
#'
#' @examples
#' x <- rnorm(1000)
#' mask <- runif(1000) < 0.1
#'
#' oversampling_factor(x, mask)
#'
#' @export
oversampling_factor <- function(
  full_values,
  sampled_mask,
  percentile = 0.99
) {

  stopifnot(
    length(full_values) == length(sampled_mask),
    is.logical(sampled_mask)
  )

  recall <- extreme_recall(
    full_values = full_values,
    sampled_mask = sampled_mask,
    percentile = percentile
  )

  # restrict to rows with valid data, so denominator matches
  # the population that recall's numerator is drawn from
  valid <- !is.na(full_values)
  sampling_fraction <- mean(sampled_mask[valid], na.rm = TRUE)

  recall / sampling_fraction
}

#' Tail-Weighted Recall
#'
#' Computes recall weighted by empirical percentile rank.
#'
#' Each observation is assigned a weight proportional to
#' percentile_rank ^ alpha, such that increasingly extreme
#' observations contribute more strongly to the final score.
#'
#' When alpha = 1, weights increase linearly with percentile rank.
#' Larger values of alpha increasingly emphasise the upper tail.
#'
#' @param full_values Numeric vector containing the complete time series.
#' @param sampled_mask Logical vector indicating sampled observations.
#' @param alpha Positive weighting exponent. Default is 2.
#'
#' @return Numeric value between 0 and 1.
#'
#' @examples
#' x <- rnorm(1000)
#' mask <- runif(1000) < 0.1
#'
#' tail_weighted_recall(x, mask)
#' tail_weighted_recall(x, mask, alpha = 5)
#'
#' @export
tail_weighted_recall <- function(
  full_values,
  sampled_mask,
  alpha = 2
) {

  stopifnot(
    length(full_values) == length(sampled_mask),
    is.logical(sampled_mask),
    alpha > 0
  )

  ranks <- rank(
    full_values,
    ties.method = "average",
    na.last = "keep"
  )

  percentiles <-
    (ranks - 1) /
    (sum(!is.na(full_values)) - 1)

  weights <- percentiles ^ alpha

  sum(weights[sampled_mask], na.rm = TRUE) /
    sum(weights, na.rm = TRUE)
}

#' Percentile Exposure
#'
#' Computes the mean empirical percentile rank of sampled
#' observations.
#'
#' Values near 0.5 indicate approximately uniform sampling
#' across the full distribution. Values greater than 0.5
#' indicate preferential sampling of larger observations.
#'
#' @param full_values Numeric vector containing the complete time series.
#' @param sampled_mask Logical vector indicating sampled observations.
#'
#' @return Numeric value between 0 and 1.
#'
#' @examples
#' x <- rnorm(1000)
#' mask <- runif(1000) < 0.1
#'
#' percentile_exposure(x, mask)
#'
#' @export
percentile_exposure <- function(
  full_values,
  sampled_mask
) {

  stopifnot(
    length(full_values) == length(sampled_mask),
    is.logical(sampled_mask)
  )

  ranks <- rank(
    full_values,
    ties.method = "average",
    na.last = "keep"
  )

  percentiles <-
    (ranks - 1) /
    (sum(!is.na(full_values)) - 1)

  mean(percentiles[sampled_mask], na.rm = TRUE)
}

#' Extreme Sampling Metrics
#'
#' Computes a suite of metrics for evaluating how effectively a
#' sampling strategy captures extreme observations.
#'
#' @param full_values Numeric vector containing the complete time series.
#' @param sampled_mask Logical vector indicating sampled observations.
#' @param percentile Percentile threshold used by Extreme Recall
#' and Oversampling Factor. Default is 0.99.
#' @param alpha Weighting exponent used by Tail-Weighted Recall.
#' Default is 2.
#'
#' @return A tibble with one row containing:
#' \describe{
#'   \item{extreme_recall}{Extreme Recall score}
#'   \item{oversampling_factor}{Oversampling Factor}
#'   \item{tail_weighted_recall}{Tail-Weighted Recall}
#'   \item{percentile_exposure}{Percentile Exposure}
#'   \item{percentile}{Percentile threshold used}
#'   \item{alpha}{Tail-weighting exponent used}
#' }
#'
#' @export
extreme_sampling_metrics <- function(
  full_values,
  sampled_mask,
  percentile = 0.99,
  alpha = 2
) {

  if (anyNA(sampled_mask)) {
    stop(
      "`sampled_mask` contains NA value(s) at position(s): ",
      paste(which(is.na(sampled_mask)), collapse = ", "),
      ". Masks must be fully TRUE/FALSE with no NA before being ",
      "passed to extreme_sampling_metrics() -- ",
      "coerce NA to FALSE upstream if missingness should be treated ",
      "as 'not sampled', e.g. `mask[is.na(mask)] <- FALSE`."
    )
  }

  tibble::tibble(
    percentile = percentile,
    alpha = alpha,
    extreme_recall = extreme_recall(
      full_values,
      sampled_mask,
      percentile
    ),
    oversampling_factor = oversampling_factor(
      full_values,
      sampled_mask,
      percentile
    ),
    tail_weighted_recall = tail_weighted_recall(
      full_values,
      sampled_mask,
      alpha
    ),
    percentile_exposure = percentile_exposure(
      full_values,
      sampled_mask
    )
  )
}

