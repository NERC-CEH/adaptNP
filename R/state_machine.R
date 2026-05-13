## State machine to identify state of a storm event hydrograph of river flow based on Wong and Kerkez (2016) WRR

## the possible states are
states <- c(
  "BASEFLOW",
  "ONSET",
  "RISING_INFLECTION",
  "PEAK",
  "FALLING_INFLECTION",
  "RETURN_TO_BASEFLOW"
)

# ## parameters
# params <- list(
#   # forecast_prob_thresh = 0.10,     # 10% POP
#   # forecast_rain_thresh = 5,        # mm/hour
#   event_frac_thresh <- 0.25,  # 25% above baseflow
#   onset_slope_thresh   = 7.5 / 5 /10 ,  # m3/s per min (paper value), may reduce to 0.05
#   baseflow_tol_frac    = 0.01,     # 10% of baseflow
#   eps                  = 1e-4      # 1e-2 or 1e-6
# )

kernel_smooth <- function(t, y, t0, l = 10) {
  w <- exp(-0.5 * ((t - t0) / l)^2)
  sum(w * y) / sum(w)
}

## Kernel smoother + derivatives (sec 3.1)
estimate_state <- function(
  time,
  y,
  kernel_l = 60,
  time_units = c("auto", "secs", "mins", "hours", "days", "weeks"),
  derivative_units = c("per_second", "per_minute")
) {
  time_units <- match.arg(time_units)
  derivative_units <- match.arg(derivative_units)

  # ---- time handling ----
  if (inherits(time, c("POSIXct", "POSIXlt"))) {

    units_map <- c(
      auto  = "secs",
      secs  = "secs",
      mins  = "mins",
      hours = "hours",
      days  = "days",
      weeks = "weeks"
    )

    t <- as.numeric(difftime(
      time,
      min(time, na.rm = TRUE),
      units = units_map[time_units]
    ))
  } else if (is.numeric(time)) {
    t <- time
  } else {
    stop("time must be POSIXct or numeric")
  }

  n <- length(y)

  # ---- kernel smoothing ----
  x_hat <- numeric(n)
  for (i in seq_len(n)) {
    idx <- max(1, i - 10):min(n, i + 10)
    w <- exp(-0.5 * ((t[idx] - t[i]) / kernel_l)^2)
    x_hat[i] <- sum(w * y[idx], na.rm = TRUE) / sum(w, na.rm = TRUE)
  }

  # ---- derivatives ----
  dt  <- diff(t)
  dx  <- diff(x_hat) / dt
  ddx <- diff(dx) / dt[-1]

  if (derivative_units == "per_minute") {
    dx  <- dx  * 60
    ddx <- ddx * 60
  }

  list(
    time_numeric = t,
    x   = x_hat,
    dx  = c(NA, dx),
    ddx = c(NA, NA, ddx)
  )
}

## state machine logic (figure 4)
update_state <- function(
  prev_state,
  Q, dQ, ddQ,
  baseflow_Q,
  forecast_prob,
  forecast_rain,
  params
) {
  with(params, {
    
    # --- BASEFLOW ---
    if (prev_state == "BASEFLOW") {
      
      # Weather forecast trigger >> can skip if not weather data
      if (forecast_prob > forecast_prob_thresh &&
          forecast_rain > forecast_rain_thresh) {
        return("ONSET")
      }
      
      # Hydrologic trigger
      if (!is.na(dQ) && dQ > onset_slope_thresh) {
        return("ONSET")
      }

      # flow magnitude based trigger (not in Wong and Kerkez)
      if (Q > baseflow_Q * (1 + event_frac_thresh)) {
        return("ONSET")
      }  
      return("BASEFLOW")
    }
    
    # --- ONSET ---
    if (prev_state == "ONSET") {
      if (!is.na(ddQ) && ddQ > 0) {
        return("RISING_INFLECTION")
      }
      return("ONSET")
    }
    
    # --- RISING INFLECTION ---
    if (prev_state == "RISING_INFLECTION") {
      if (!is.na(dQ) && abs(dQ) < eps) {
        return("PEAK")
      }
      return("RISING_INFLECTION")
    }
    
    # --- PEAK ---
    if (prev_state == "PEAK") {
      if (!is.na(ddQ) && ddQ < 0) {
        return("FALLING_INFLECTION")
      }
      return("PEAK")
    }
    
    # --- FALLING INFLECTION ---
    if (prev_state == "FALLING_INFLECTION") {
      if (Q <= baseflow_Q * (1 + baseflow_tol_frac)) {
        return("RETURN_TO_BASEFLOW")
      }
      return("FALLING_INFLECTION")
    }
    
    # --- RETURN TO BASEFLOW ---
    if (prev_state == "RETURN_TO_BASEFLOW") {
      if (Q <= baseflow_Q * (1 + baseflow_tol_frac)) {
        return("BASEFLOW")
      }
      return("RETURN_TO_BASEFLOW")
    }
    
    # --- ALLOW RE-ONSET DURING RECESSION (only qualitative in Wong and Kerkez) ---
    reonset_thresh <- onset_slope_thresh # set as equal for now
    if (prev_state %in% c("FALLING_INFLECTION", "RETURN_TO_BASEFLOW") &&
      dQ > reonset_thresh) {
      return("ONSET")
    }

    prev_state
  })
}

## update state function for no weather forecast
update_state_no_forecast <- function(
  prev_state,
  Q,
  dQ,
  ddQ,
  baseflow_Q,
  params
) {
  with(params, {

    # ---- BASEFLOW → ONSET ----
    if (prev_state == "BASEFLOW") {
      # flow gradient based trigger
      if (!is.na(dQ) && dQ > onset_slope_thresh) {
        return("ONSET")
      }
      # flow magnitude based trigger (not in Wong and Kerkez)
      if (Q > baseflow_Q * (1 + event_frac_thresh)) {
        return("ONSET")
      }  
      return("BASEFLOW")
    }


    # ---- ONSET → RISING_INFLECTION ----
    if (prev_state == "ONSET" &&
        !is.na(ddQ) && ddQ > 0) {
      return("RISING_INFLECTION")
    }

    # ---- RISING_INFLECTION → PEAK ----
    if (prev_state == "RISING_INFLECTION" &&
        !is.na(dQ) && abs(dQ) < eps) {
      return("PEAK")
    }

    # ---- PEAK → FALLING_INFLECTION ----
    if (prev_state == "PEAK" &&
        !is.na(ddQ) && ddQ < 0) {
      return("FALLING_INFLECTION")
    }

    # ---- FALLING_INFLECTION → RETURN_TO_BASEFLOW ----
    if (prev_state == "FALLING_INFLECTION" &&
        Q <= baseflow_Q * (1 + baseflow_tol_frac)) {
      return("RETURN_TO_BASEFLOW")
    }

    # ---- RETURN_TO_BASEFLOW → BASEFLOW ----
    if (prev_state == "RETURN_TO_BASEFLOW" &&
        Q <= baseflow_Q * (1 + baseflow_tol_frac)) {
      return("BASEFLOW")
    }

    # --- ALLOW RE-ONSET DURING RECESSION (only qualitative in Wong and Kerkez) ---
    reonset_thresh <- onset_slope_thresh # set as equal for now
    if (prev_state %in% c("FALLING_INFLECTION", "RETURN_TO_BASEFLOW") &&
      dQ > reonset_thresh) {
      return("ONSET")
    }

    prev_state
  })
}

#' Run an event-driven state machine on flow data
#'
#' Applies a state machine to a univariate flow time series to detect
#' regime changes (e.g. baseflow, rising limb, peak, recession) based on
#' estimated signal derivatives. Only state transitions are returned.
#'
#' @param time A vector of timestamps (POSIXct or convertible), representing
#'   the time of each observation.
#' @param flow Numeric vector of flow (or discharge) values. Must be the
#'   same length as `time`.
#' @param params A list of parameters controlling state transitions.
#'   Passed to \code{update_state_no_forecast()}.
#' @param kernel_l Numeric. Length scale of the smoothing kernel used in
#'   state estimation. Default is `60`.
#' @param time_units Character string specifying the time units of the input
#'   series (e.g. `"mins"`, `"hours"`). Passed to \code{estimate_state()}.
#' @param derivative_units Character string specifying the units of the
#'   estimated derivatives (e.g. `"per_minute"`). Passed to \code{estimate_state()}.
#'
#' @return A data frame containing only state transitions with columns:
#' \itemize{
#'   \item `time`: timestamp at which a state change occurs
#'   \item `state`: the new state entered at that time
#' }
#'
#' @details
#' The function first estimates a smoothed version of the flow signal and its
#' first and second derivatives using \code{estimate_state()}.
#'
#' A baseline flow (`baseflow_Q`) is computed as the median of the input
#' flow series. This is used as a reference level in state transitions.
#'
#' The state machine is initialised in the `"BASEFLOW"` state and updated
#' sequentially using \code{update_state_no_forecast()}, which determines
#' the next state based on:
#' \itemize{
#'   \item current flow (`Q`)
#'   \item first derivative (`dQ`)
#'   \item second derivative (`ddQ`)
#'   \item baseline flow (`baseflow_Q`)
#'   \item user-defined parameters (`params`)
#' }
#'
#' Only points where the state changes are recorded, resulting in a compact
#' representation of regime transitions rather than a full time series.
#'
#' @examples
#' # Simulated example
#' \dontrun{
#' set.seed(1)
#' time <- seq.POSIXt(Sys.time(), by = "min", length.out = 200)
#' flow <- cumsum(rnorm(200))
#'
#' params <- list(
#'   rise_threshold = 0.1,
#'   fall_threshold = -0.1
#' )
#'
#' transitions <- run_state_machine(
#'   time = time,
#'   flow = flow,
#'   params = params
#' )
#'
#' head(transitions)
#' }
#'
#' @seealso \code{\link{estimate_state}}, \code{\link{update_state_no_forecast}}
#'
#' @export
## running the sampler (event-driven)
run_state_machine <- function(
  time,
  flow,
  params,
  kernel_l = 60,
  time_units = "mins",
  derivative_units = "per_minute"
) {
  stopifnot(length(time) == length(flow))

  # ---- Estimate smoothed state and derivatives ----
  est <- estimate_state(
    time = time,
    y = flow,
    kernel_l = kernel_l,
    time_units = time_units,
    derivative_units = derivative_units
  )

  # ---- Reference baseflow ----
  baseflow_Q <- median(flow, na.rm = TRUE)
  # baseflow_Q <- quantile(flow, 0.1, na.rm = TRUE)
  # ---- Initial state ----
  state <- "BASEFLOW"

  # ---- Output: state transitions only ----
  transitions <- data.frame(
    time  = as.POSIXct(character()),
    state = character(),
    stringsAsFactors = FALSE
  )

  # ---- Main loop ----
  for (i in seq_along(time)) {

    new_state <- update_state_no_forecast(
      prev_state = state,
      Q  = est$x[i],
      dQ = est$dx[i],
      ddQ = est$ddx[i],
      baseflow_Q = baseflow_Q,
      params = params
    )

    # record only state transitions
    if (!identical(new_state, state)) {
      transitions <- rbind(
        transitions,
        data.frame(time = time[i], state = new_state)
      )
    }

    state <- new_state
  }

  transitions
}


#' Plot flow series with state transitions
#'
#' Visualises a time series of flow alongside state transitions produced
#' by \code{\link{run_state_machine}}. The function overlays the flow signal
#' with vertical lines marking transition points and optional annotations
#' for detected states.
#'
#' @param time A vector of timestamps (POSIXct or convertible).
#' @param flow Numeric vector of flow values.
#' @param transitions A data frame returned by \code{run_state_machine()},
#'   containing `time` and `state` columns.
#' @param show_labels Logical. If `TRUE`, state labels are shown at transition
#'   points. Default is `TRUE`.
#' @param line_color Color for the flow time series. Default `"black"`.
#'
#' @return A ggplot object.
#'
#' @details
#' The plot shows:
#' \itemize{
#'   \item the flow time series as a line
#'   \item vertical dashed lines indicating state transitions
#'   \item optional labels indicating the new state at each transition
#' }
#'
#' This function is designed for use in pkgdown vignettes and supports
#' further customisation via standard ggplot2 layers.
#'
#' @examples
#' \dontrun{
#' transitions <- run_state_machine(time, flow, params)
#'
#' plot_state_machine(time, flow, transitions)
#' }
#'
#' @seealso \code{\link{run_state_machine}}
#'
#' @export
plot_state_machine <- function(
  time,
  flow,
  transitions,
  show_labels = TRUE,
  line_color = "black"
) {

  stopifnot(length(time) == length(flow))

  df <- data.frame(time = time, flow = flow)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = time, y = flow)) +
    ggplot2::geom_line(color = line_color) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Time",
      y = "Flow",
      title = "Flow with State Transitions"
    )

  # Add vertical lines for transitions
  if (!is.null(transitions) && nrow(transitions) > 0) {
    p <- p +
      ggplot2::geom_vline(
        data = transitions,
        ggplot2::aes(xintercept = as.numeric(time)),
        linetype = "dashed",
        color = "red",
        alpha = 0.7
      )
  }

  # Add labels
  if (show_labels && !is.null(transitions) && nrow(transitions) > 0) {
    p <- p +
      ggplot2::geom_text(
        data = transitions,
        ggplot2::aes(
          x = time,
          y = max(flow, na.rm = TRUE),
          label = state
        ),
        angle = 90,
        vjust = -0.5,
        size = 3
      )
  }

  return(p)
}