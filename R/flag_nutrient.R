#' Flag online nutrient sensor data using QARTOD-style tests
#'
#' Applies a set of automated, causal (trailing-window) quality control tests
#' to a regularly spaced nutrient time series and returns QARTOD flag codes.
#' Intended as a first-pass screen before manual review.
#'
#' @details
#' Tests are applied in this order; a later test never downgrades an existing
#' fail flag:
#' \enumerate{
#'   \item \strong{Gross range}: values outside \code{[lo, hi]} are flagged 4 (fail).
#'   \item \strong{Spike}: \eqn{|x - median_w| > k_{spike} \cdot sd_w} is flagged 3 (suspect).
#'   \item \strong{Rate of change}: \eqn{|\Delta x| > k_{roc} \cdot sd_{w}} (SD
#'     from the previous time step) is flagged 3 (suspect).
#'   \item \strong{Flat line}: rolling variance over \code{flat_w} points
#'     below \code{flat_tol} is flagged 3 (suspect).
#'   \item \strong{Missing}: \code{NA} values are flagged 9.
#' }
#' All rolling statistics are trailing windows from the \pkg{roll} package, so
#' each flag uses only data available up to that time (suitable for real-time
#' use). The series must be regularly spaced, with \code{NA} inserted for
#' missing timestamps, because \pkg{roll} assumes equal spacing.
#'
#' The spike test includes the current point in its own window; for a stricter
#' test, lag the median and SD by one step. Rate-of-change flags during storm
#' events are often real, so check discharge before rejecting them.
#'
#' @param x Numeric vector of nutrient concentrations, regularly spaced in time.
#' @param lo,hi Numeric. Lower and upper gross range limits (e.g., sensor
#'   specification or site-plausible range).
#' @param w Integer. Window length (in samples) for the rolling median and SD.
#'   Default 96 (one day of 15-minute data).
#' @param k_spike Numeric. Spike threshold in rolling SD units. Default 4.
#' @param k_roc Numeric. Rate-of-change threshold in rolling SD units. Default 3.
#' @param flat_w Integer. Window length (in samples) for the flat-line test.
#'   Default 6.
#' @param flat_tol Numeric. Rolling variance below which a window is considered
#'   flat. Default 1e-8.
#'
#' @return Integer vector the same length as \code{x} with QARTOD flags:
#'   1 = pass, 3 = suspect, 4 = fail, 9 = missing.
#'
#' @references
#' U.S. IOOS (2018). \emph{Manual for Real-Time Quality Control of Dissolved
#' Nutrients Observations} (QARTOD).
#'
#' Pellerin, B.A., et al. (2013). \emph{Optical techniques for the determination
#' of nitrate in environmental waters}. USGS Techniques and Methods 1-D5.
#'
#' @examples
#' set.seed(1)
#' x <- 2 + sin(seq(0, 20, length.out = 500)) + rnorm(500, sd = 0.05)
#' x[100] <- 8          # spike
#' x[300:310] <- x[300] # flat line
#' x[400] <- -1         # out of range
#' x[450] <- NA         # missing
#' fl <- flag_nutrient(x, lo = 0, hi = 28)
#' table(fl)
#'
#' @importFrom roll roll_median roll_sd roll_var
#' @export
flag_nutrient <- function(x, lo, hi, w = 96, k_spike = 4, k_roc = 3,
                          flat_w = 6, flat_tol = 1e-8) {
  flag <- rep(1L, length(x))

  # gross range
  flag[x < lo | x > hi] <- 4L

  # spike: deviation from trailing rolling median vs rolling sd
  med <- roll::roll_median(x, width = w, min_obs = w / 2)
  sdv <- roll::roll_sd(x, width = w, min_obs = w / 2)
  spike <- abs(x - med) > k_spike * sdv
  flag[which(spike & flag < 3L)] <- 3L

  # rate of change (uses sd up to the previous point)
  roc <- abs(c(NA, diff(x))) > k_roc * c(NA, utils::head(sdv, -1))
  flag[which(roc & flag < 3L)] <- 3L

  # flat line: near-zero variance over flat_w consecutive points
  flat <- roll::roll_var(x, width = flat_w) < flat_tol
  flag[which(flat & flag < 3L)] <- 3L

  # missing
  flag[is.na(x)] <- 9L

  flag
}


#' Flag SUNA V2 nitrate data using instrument diagnostics
#'
#' Applies per-test QARTOD-style flags to SUNA V2 nitrate data logged at a
#' regular interval (default 10 minutes), combining instrument diagnostics with
#' the statistical tests in \code{flag_nutrient()}. Each test gets its own flag
#' column, and \code{qc_primary} is the worst flag across tests.
#'
#' @details
#' Tests (1 = pass, 3 = suspect, 4 = fail, 9 = missing nitrate):
#' \describe{
#'   \item{qc_logger}{Suspect if the logger needed communication retries.}
#'   \item{qc_power}{Fail if supply voltage is outside the 8-18 VDC spec
#'     (8-15 VDC with a wiper); suspect below \code{supply_warn}.}
#'   \item{qc_lamp}{Fail if cumulative lamp time did not increase (lamp did not
#'     fire, or counter reset) or lamp temperature reached \code{lamp_temp_max};
#'     suspect if lamp temperature is near that limit, the lamp is past its rated
#'     life, or lamp voltage deviates from its recent level.}
#'   \item{qc_light}{Light signal (spectral minus dark counts) relative to a
#'     clean-window baseline taken right after each service visit. Suspect below
#'     \code{light_suspect}, fail below \code{light_fail} or if signal <= 0.
#'     Low light means fouling or optically thick water (turbidity, CDOM);
#'     either way the nitrate fit is less reliable.}
#'   \item{qc_dark}{Suspect if the dark average departs from its recent
#'     rolling median by more than \code{k_dark} rolling SDs.}
#'   \item{qc_electronics}{Suspect if the regulated voltage deviates from its
#'     recent level, or spectrometer temperature is outside 0-35 C.}
#'   \item{qc_humidity}{Suspect if internal humidity has risen more than
#'     \code{hum_rise} percentage points above its post-service baseline
#'     (possible leak or exhausted desiccant).}
#'   \item{qc_units}{Suspect if mg N/L and molar nitrate disagree by more than
#'     1 percent (assumes \code{SUNA_Nitrate_Mol} is in micromolar).}
#'   \item{qc_stats}{Range, spike, rate-of-change and flat-line tests from
#'     \code{flag_nutrient()} on \code{SUNA_Nitrate_mgL}.}
#' }
#' Reference levels use trailing windows lagged by one step, so each flag uses
#' only earlier data. Missing diagnostic values are treated as pass. The data
#' must be regularly spaced; a warning is issued if RECORD or TIMESTAMP show gaps.
#'
#' @param df Data frame with columns TIMESTAMP (POSIXct), RECORD,
#'   SUNA_Nitrate_Mol, SUNA_Nitrate_mgL, SUNA_Average_Spectral_Meas,
#'   SUNA_Average_Dark_Meas, retries, SUNA_LampT, SUNA_Spectrometer_Temp,
#'   SUNA_Lamp_Time_secs, SUNA_Int_Hum, SUNA_LampV, SUNA_RegV, SUNA_SupplyV.
#' @param service_times POSIXct vector of cleaning/service times. Light and
#'   humidity baselines are reset after each. If \code{NULL}, the start of the
#'   record is the only baseline.
#' @param lo,hi Gross range limits for nitrate in mg N/L passed to
#'   \code{flag_nutrient()}. Set \code{lo} slightly below zero so near-zero
#'   noise is not failed.
#' @param interval_s Logging interval in seconds. Default 600 (10 minutes).
#' @param w Rolling window in samples. Default 144 (24 h at 10 minutes).
#' @param wiper Logical. If \code{TRUE}, uses the 15 VDC upper supply limit.
#' @param supply_warn Supply voltage below which data are suspect. Default 9.
#' @param lamp_temp_max,lamp_temp_warn Lamp temperature fail and suspect
#'   limits in C. Defaults 35 and 33.
#' @param lamp_life_s Rated lamp life in seconds. Default 900 h.
#' @param volt_tol Relative tolerance for lamp and regulated voltage versus
#'   their recent rolling median. Default 0.05 (5 percent).
#' @param light_suspect,light_fail Fractions of the baseline light signal for
#'   suspect and fail. Defaults 0.5 and 0.2; tune per site.
#' @param baseline_n Samples after each service used for baselines. Default 6.
#' @param k_dark Dark outlier threshold in rolling SD units. Default 4.
#' @param hum_rise Allowed humidity rise in percentage points. Default 10.
#' @param ... Further arguments passed to \code{flag_nutrient()}.
#'
#' @return \code{df} with added per-test flag columns, \code{light_rel}
#'   (light signal as a fraction of baseline), and \code{qc_primary}.
#'
#' @seealso \code{flag_nutrient()}
#' @importFrom roll roll_median roll_sd
#' @export
flag_suna <- function(df, service_times = NULL, lo = -0.05, hi = 42,
                      interval_s = 600, w = 144, wiper = FALSE,
                      supply_warn = 9, lamp_temp_max = 35, lamp_temp_warn = 33,
                      lamp_life_s = 900 * 3600, volt_tol = 0.05,
                      light_suspect = 0.5, light_fail = 0.2, baseline_n = 6,
                      k_dark = 4, hum_rise = 10, ...) {
  n <- nrow(df)
  lag1 <- function(v) c(NA, utils::head(v, -1))
  qflag <- function(fail = FALSE, suspect = FALSE) {
    out <- rep(1L, n)
    out[which(rep_len(suspect, n))] <- 3L
    out[which(rep_len(fail, n))] <- 4L
    out
  }
  ref_med <- function(v) lag1(roll::roll_median(v, width = w, min_obs = w / 2))
  baseline <- function(v, seg) {
    stats::ave(v, seg, FUN = function(s) stats::median(utils::head(s[!is.na(s)], baseline_n)))
  }

  # regular spacing check
  dt <- diff(as.numeric(df$TIMESTAMP))
  if (any(dt != interval_s, na.rm = TRUE) || any(diff(df$RECORD) != 1, na.rm = TRUE)) {
    warning("Irregular TIMESTAMP or RECORD steps: regularize the series (insert NA rows) before flagging.")
  }

  # service segments for baselines
  seg <- if (is.null(service_times)) rep(1L, n) else
    findInterval(as.numeric(df$TIMESTAMP), sort(as.numeric(service_times))) + 1L

  # logger communications
  df$qc_logger <- qflag(suspect = df$retries > 0)

  # supply power
  sv <- df$SUNA_SupplyV
  df$qc_power <- qflag(fail = sv < 8 | sv > if (wiper) 15 else 18,
                       suspect = sv < supply_warn)

  # lamp
  dlamp <- c(NA, diff(df$SUNA_Lamp_Time_secs))
  lv_ref <- ref_med(df$SUNA_LampV)
  df$qc_lamp <- qflag(
    fail = dlamp <= 0 | df$SUNA_LampT >= lamp_temp_max,
    suspect = df$SUNA_LampT >= lamp_temp_warn |
      df$SUNA_Lamp_Time_secs > lamp_life_s |
      abs(df$SUNA_LampV - lv_ref) / lv_ref > volt_tol
  )

  # light signal relative to post-service baseline
  sig <- df$SUNA_Average_Spectral_Meas - df$SUNA_Average_Dark_Meas
  df$light_rel <- sig / baseline(sig, seg)
  df$qc_light <- qflag(fail = sig <= 0 | df$light_rel < light_fail,
                       suspect = df$light_rel < light_suspect)

  # dark counts
  dk <- df$SUNA_Average_Dark_Meas
  dk_sd <- lag1(roll::roll_sd(dk, width = w, min_obs = w / 2))
  df$qc_dark <- qflag(suspect = abs(dk - ref_med(dk)) > k_dark * dk_sd)

  # electronics
  rv_ref <- ref_med(df$SUNA_RegV)
  st <- df$SUNA_Spectrometer_Temp
  df$qc_electronics <- qflag(
    suspect = abs(df$SUNA_RegV - rv_ref) / rv_ref > volt_tol | st < 0 | st > 35
  )

  # internal humidity rise
  hum <- df$SUNA_Int_Hum
  df$qc_humidity <- qflag(suspect = hum - baseline(hum, seg) > hum_rise)

  # unit consistency (micromolar -> mg N/L)
  mg_from_mol <- df$SUNA_Nitrate_Mol * 14.0067 / 1000
  df$qc_units <- qflag(
    suspect = abs(df$SUNA_Nitrate_mgL - mg_from_mol) > 0.01 * pmax(abs(mg_from_mol), 0.01)
  )

  # statistical tests on nitrate
  df$qc_stats <- flag_nutrient(df$SUNA_Nitrate_mgL, lo = lo, hi = hi, w = w, ...)
  df$qc_stats[df$qc_stats == 9L] <- 1L

  # primary flag
  qc_cols <- c("qc_logger", "qc_power", "qc_lamp", "qc_light", "qc_dark",
               "qc_electronics", "qc_humidity", "qc_units", "qc_stats")
  df$qc_primary <- do.call(pmax, c(df[qc_cols], na.rm = TRUE))
  df$qc_primary[is.na(df$SUNA_Nitrate_mgL)] <- 9L

  df
}
