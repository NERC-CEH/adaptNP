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

#' Estimate smoothed signals and derivatives
#'
#' Applies Gaussian kernel smoothing to a time series and estimates its first
#' and second derivatives using finite differences. The resulting smoothed
#' signal and derivatives can be used for event detection and hydrological
#' state classification with functions such as
#' [update_state_no_forecast()] and [run_state_machine()].
#'
#' The function first smooths the input signal using a Gaussian kernel with
#' bandwidth specified by `kernel_l`. It then calculates:
#'
#' \itemize{
#'   \item the smoothed signal (\eqn{x}),
#'   \item the first derivative (\eqn{dx/dt}),
#'   \item the second derivative (\eqn{d^2x/dt^2}).
#' }
#'
#' Time may be supplied as either a numeric vector or a POSIXct time series.
#' For POSIXct inputs, elapsed time is calculated relative to the first
#' observation.
#'
#' @param time A numeric or POSIXct vector of observation times.
#'
#' @param y Numeric vector containing the variable to be smoothed (for example,
#' discharge, concentration, or turbidity).
#'
#' @param kernel_l Numeric. Bandwidth of the Gaussian smoothing kernel.
#' Larger values produce smoother estimates.
#'
#' @param time_units Character string specifying the units used when converting
#' POSIXct values to elapsed time. One of:
#' \code{"auto"}, \code{"secs"}, \code{"mins"}, \code{"hours"},
#' \code{"days"}, or \code{"weeks"}.
#'
#' @param derivative_units Character string specifying the units of the
#' returned derivatives. One of:
#' \describe{
#'   \item{\code{"per_second"}}{Return derivatives per second.}
#'   \item{\code{"per_minute"}}{Return derivatives per minute.}
#' }
#'
#' @return A list with four components:
#' \describe{
#'   \item{time_numeric}{Numeric representation of the input time vector.}
#'   \item{x}{Kernel-smoothed signal.}
#'   \item{dx}{First derivative of the smoothed signal.}
#'   \item{ddx}{Second derivative of the smoothed signal.}
#' }
#'
#' @details
#' A Gaussian kernel smoother is applied locally around each observation. First
#' and second derivatives are then estimated from the smoothed series using
#' finite differences. Smoothing prior to differentiation reduces the influence
#' of measurement noise on derivative estimates.
#'
#' In hydrological applications, the derivatives can be used to identify:
#' \itemize{
#'   \item event onset through increasing flow (\code{dx > 0}),
#'   \item rising inflection points (\code{ddx > 0}),
#'   \item peak flow conditions (\code{dx ≈ 0}),
#'   \item recession dynamics (\code{ddx < 0}).
#' }
#'
#' @references
#' Wong, B. P., and Kerkez, B. Adaptive sampling methods for high-frequency
#' environmental monitoring.
#'
#' @examples
#' set.seed(123)
#'
#' time <- seq(0, 100, by = 1)
#' flow <- 10 + sin(time / 10) + rnorm(length(time), sd = 0.3)
#'
#' est <- estimate_derivatives(
#'   time = time,
#'   y = flow,
#'   kernel_l = 5
#' )
#'
#' plot(time, flow, col = "grey")
#' lines(time, est$x, col = "blue", lwd = 2)
#'
#' head(est$dx)
#' head(est$ddx)
#'
#' @seealso
#' [update_state_no_forecast()],
#' [run_state_machine()]
#'
#' @export
## Kernel smoother + derivatives (sec 3.1)
estimate_derivatives <- function(
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

#' Update hydrological event state without weather forecast information
#'
#' Updates the current event state based on observed streamflow conditions and
#' flow derivatives, using a finite-state machine adapted from the event
#' detection framework of Wong and Kerkez. This implementation relies solely on
#' observed discharge data and does not use weather forecast information.
#'
#' State transitions are determined using flow magnitude (`Q`), first
#' derivative (`dQ`), second derivative (`ddQ`), and an estimate of baseline
#' flow (`baseflow_Q`). The possible states are:
#'
#' \itemize{
#'   \item \code{"BASEFLOW"}
#'   \item \code{"ONSET"}
#'   \item \code{"RISING_INFLECTION"}
#'   \item \code{"PEAK"}
#'   \item \code{"FALLING_INFLECTION"}
#'   \item \code{"RETURN_TO_BASEFLOW"}
#' }
#'
#' State transitions include:
#' \enumerate{
#'   \item BASEFLOW \eqn{\rightarrow} ONSET
#'   \item ONSET \eqn{\rightarrow} RISING_INFLECTION
#'   \item RISING_INFLECTION \eqn{\rightarrow} PEAK
#'   \item PEAK \eqn{\rightarrow} FALLING_INFLECTION
#'   \item FALLING_INFLECTION \eqn{\rightarrow} RETURN_TO_BASEFLOW
#'   \item RETURN_TO_BASEFLOW \eqn{\rightarrow} BASEFLOW
#' }
#'
#' Re-onset events are also permitted during the recession phase if flow rises
#' sufficiently rapidly.
#'
#' @param prev_state Character string giving the previous hydrological state.
#' Must be one of \code{"BASEFLOW"}, \code{"ONSET"},
#' \code{"RISING_INFLECTION"}, \code{"PEAK"},
#' \code{"FALLING_INFLECTION"}, or \code{"RETURN_TO_BASEFLOW"}.
#'
#' @param Q Numeric. Current discharge value.
#'
#' @param dQ Numeric. First derivative of discharge (rate of change of flow).
#'
#' @param ddQ Numeric. Second derivative of discharge (change in flow
#' acceleration).
#'
#' @param baseflow_Q Numeric. Estimated baseline discharge used to identify
#' departures from and returns to background flow conditions.
#'
#' @param params A named list containing state-transition thresholds:
#' \describe{
#'   \item{onset_slope_thresh}{Minimum flow gradient required to trigger an event onset.}
#'   \item{event_frac_thresh}{Fractional increase above baseflow required to trigger onset.}
#'   \item{baseflow_tol_frac}{Fractional tolerance used to determine return to baseflow.}
#'   \item{eps}{Small positive value used to identify near-zero flow gradients at the event peak.}
#' }
#'
#' @return A character string containing the updated hydrological state.
#'
#' @references
#' Wong, B. P. and Kerkez, B. (2024). An adaptive storm-event sampling
#' framework for high-frequency water quality monitoring.
#'
#' @examples
#' params <- list(
#'   onset_slope_thresh = 0.05,
#'   event_frac_thresh = 0.20,
#'   baseflow_tol_frac = 0.10,
#'   eps = 0.01
#' )
#'
#' update_state_no_forecast(
#'   prev_state = "BASEFLOW",
#'   Q = 12,
#'   dQ = 0.08,
#'   ddQ = 0,
#'   baseflow_Q = 10,
#'   params = params
#' )
#'
#' @keywords internal



#' Update event-detection state machine with no weather forecast
#' 
#' @description
#' Computes the next state of a hydrograph event-detection finite state machine
#' from the current state and the local flow dynamics, for the case where no
#' weather forecast is available. The machine walks a storm event through the
#' sequence BASEFLOW -> ONSET -> RISING_INFLECTION -> PEAK ->
#' FALLING_INFLECTION -> RETURN_TO_BASEFLOW -> BASEFLOW, with an additional
#' transition allowing a new ONSET during recession (re-onset).
#'
#' @details
#' Transitions are driven by the flow magnitude and its first and second time
#' derivatives:
#' \itemize{
#'   \item \strong{BASEFLOW -> ONSET}: triggered when the flow gradient exceeds
#'     \code{onset_slope_thresh}, or (as an extension not in Wong and Kerkez)
#'     when flow rises more than \code{event_frac_thresh} above baseflow.
#'   \item \strong{ONSET -> RISING_INFLECTION}: when the flow is accelerating
#'     (\code{ddQ > 0}).
#'   \item \strong{RISING_INFLECTION -> PEAK}: when the gradient flattens
#'     (\code{abs(dQ) < eps}).
#'   \item \strong{PEAK -> FALLING_INFLECTION}: when the flow is decelerating
#'     (\code{ddQ < 0}).
#'   \item \strong{FALLING_INFLECTION -> RETURN_TO_BASEFLOW}: when flow falls
#'     back to within \code{baseflow_tol_frac} of baseflow.
#'   \item \strong{RETURN_TO_BASEFLOW -> BASEFLOW}: when flow remains within
#'     \code{baseflow_tol_frac} of baseflow.
#'   \item \strong{Re-onset}: from either recession state
#'     (FALLING_INFLECTION or RETURN_TO_BASEFLOW), a renewed steep rise
#'     (\code{dQ > reonset_thresh}) returns the machine to ONSET. This is only
#'     described qualitatively in Wong and Kerkez.
#' }
#' If no transition condition is met, the current state is returned unchanged.
#' \code{NA} values in \code{dQ} or \code{ddQ} suppress the transitions that
#' depend on them.
#'
#' @param prev_state Character scalar. The current state, one of
#'   \code{"BASEFLOW"}, \code{"ONSET"}, \code{"RISING_INFLECTION"},
#'   \code{"PEAK"}, \code{"FALLING_INFLECTION"}, \code{"RETURN_TO_BASEFLOW"}.
#' @param Q Numeric scalar. Current flow (e.g. m3/s).
#' @param dQ Numeric scalar. First time derivative of flow (flow gradient).
#'   May be \code{NA}.
#' @param ddQ Numeric scalar. Second time derivative of flow (flow
#'   acceleration). May be \code{NA}.
#' @param baseflow_Q Numeric scalar. The current estimate of baseflow, used as
#'   the reference level for onset and return-to-baseflow thresholds.
#' @param params A list of tuning parameters, evaluated within the function via
#'   \code{\link[base]{with}}. Must contain:
#'   \describe{
#'     \item{onset_slope_thresh}{Flow-gradient threshold for storm onset.}
#'     \item{event_frac_thresh}{Fractional rise above baseflow that also
#'       triggers onset.}
#'     \item{eps}{Tolerance on the gradient for detecting the peak
#'       (near-zero slope).}
#'     \item{baseflow_tol_frac}{Fractional tolerance around baseflow for
#'       declaring return to, and continuation of, baseflow.}
#'   }
#'
#' @return A character scalar giving the next state. If no transition fires,
#'   \code{prev_state} is returned unchanged.
#'
#' @references
#' Wong, B. P., & Kerkez, B. (referenced for the underlying state-machine
#' formulation).
#'
#' @examples
#' params <- list(
#'   onset_slope_thresh = 0.5,
#'   event_frac_thresh  = 0.2,
#'   eps                = 0.01,
#'   baseflow_tol_frac  = 0.1
#' )
#' update_state_no_forecast(
#'   prev_state = "BASEFLOW",
#'   Q = 10, dQ = 1.0, ddQ = 0.2,
#'   baseflow_Q = 5, params = params
#' )
#'
#' @export
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
#'   series (e.g. `"mins"`, `"hours"`). Passed to \code{estimate_derivatives()}.
#' @param derivative_units Character string specifying the units of the
#'   estimated derivatives (e.g. `"per_minute"`). Passed to \code{estimate_derivatives()}.
#'
#' @return A data frame containing only state transitions with columns:
#' \itemize{
#'   \item `time`: timestamp at which a state change occurs
#'   \item `state`: the new state entered at that time
#' }
#'
#' @details
#' The function first estimates a smoothed version of the flow signal and its
#' first and second derivatives using \code{estimate_derivatives()}.
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
#' @seealso \code{\link{estimate_derivatives}}, \code{\link{update_state_no_forecast}}
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
  est <- estimate_derivatives(
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