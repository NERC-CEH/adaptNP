#' Hourly river flow and water quality data at The Cut, Berkshire
#'
#' @description
#' Hourly river flow and water quality data collected at The Cut, Berkshire,
#' England from May 2010 to February 2012 by the Centre for Ecology & Hydrology
#' (now UKCEH).
#'
#' This dataset comprises hourly physical and nutrient monitoring data from
#' The Cut at Bray Marina (National Grid reference SU915786). Variables include
#' total phosphorus, total reactive phosphorus, ammonium, conductivity,
#' temperature, dissolved oxygen, pH, turbidity and chlorophyll.
#'
#' Hourly averaged flow data from the Environment Agency gauging station at
#' Binfield (approximately 10 km upstream) are also included. The monitoring
#' programme was funded by EPSRC through the LIMPIDS project.
#'
#' @format A data frame (tibble) with 15,636 rows and 11 variables:
#' \describe{
#'   \item{Date / time}{Date and time of observation (POSIXct)}
#'   \item{Flow at Binfield gauging station (m3/s)}{Flow at Binfield gauging station (m3 per second)}
#'   \item{Total Reactive Phosphorus (mg/l)}{Total reactive phosphorus (mg per litre)}
#'   \item{Total Phosphorus (mg/l)}{Total phosphorus (mg per litre)}
#'   \item{Conductivity (us/cm)}{Electrical conductivity}
#'   \item{Turbidity (NTU)}{Turbidity (NTU)}
#'   \item{Total chlorophyll (ug/l)}{Total chlorophyll (micrograms per litre)}
#'   \item{Dissolved Oxygen (\% saturation)}{Dissolved oxygen (percent saturation)}
#'   \item{pH}{Acidity (unitless)}
#'   \item{Temperature (C)}{Water temperature (degrees C)}
#'   \item{NH4 (mg N /l)}{Ammonium (mg N per litre)}
#' }
#'
#' @references
#' Bowes, M. J., Gozzard, E., Newman, J., Loewenthal, M., Halliday, S.,
#' Skeffington, R. A., Jarvie, H. P., Wade, A., & Palmer-Felgate, E. (2015).
#' \emph{Hourly physical and nutrient monitoring data for The Cut, Berkshire
#' (2010--2012)}.
#' NERC Environmental Information Data Centre.
#' \doi{10.5285/abe4dd7c-a340-4595-a57f-8c1446ff7656}
#'
#' @source
#' \url{https://doi.org/10.5285/abe4dd7c-a340-4595-a57f-8c1446ff7656}
#'
"TheCutData"


#' High resolution physio-chemical data collected from an automatic buoy at
#' Esthwaite Water, England (2025)
#'
#' @format A data frame (tibble) with 126,472 rows and 23 columns:
#' \describe{
#'   \item{TIMESTAMP}{Date and time}
#'   \item{others}{Various physical, chemical and meteorological parameters}
#' }
#'
#' @seealso
#' [Esthwaite_Buoy_SUNA_Data()],
#' [Esthwaite_Buoy_OLD]
#'
"Esthwaite_Buoy_HiRes"


#' High resolution optical nitrate data at Esthwaite Water, England (2025)
#'
#' @format A data frame (tibble) with 25,292 rows and 14 columns:
#' \describe{
#'   \item{TIMESTAMP}{Date and time}
#'   \item{SUNA_Nitrate_mgL}{SUNA nitrate concentrations in mg/L collected every 10 minutes}
#'   \item{Other columns}{Additional monitoring variables not typically used in package workflows}
#' }
#'
"Esthwaite_Buoy_SUNA_Data"


#' Esthwaite Water buoy monitoring data (2008--2011)
#'
#' @description
#' Data from an automatic water monitoring buoy at Esthwaite Water, England,
#' collected between 2008 and 2011.
#'
#' The dataset contains high-frequency measurements of water temperature at
#' multiple depths, alongside meteorological variables.
#'
#' This dataset consists of hourly lake temperature, air temperature, solar
#' irradiance and wind speed data from an automatic water monitoring buoy on
#' Esthwaite Water, a lake in north-west England. Lake temperatures were
#' measured at multiple depths (see supporting documentation). Measurements
#' were taken every 4 minutes and aggregated to hourly averages. The data were
#' collected by the Centre for Ecology & Hydrology between 2008 and 2011.
#'
#' @format A data frame with 35,064 rows and 16 variables:
#' \describe{
#'   \item{Date_GMT}{Date and time of observation (POSIXct)}
#'   \item{Water_temperature_0.5m}{Water temperature at 0.5 m depth (degrees C)}
#'   \item{Water_temperature_1m}{Water temperature at 1 m depth (degrees C)}
#'   \item{Water_temperature_2m}{Water temperature at 2 m depth (degrees C)}
#'   \item{Water_temperature_3m}{Water temperature at 3 m depth (degrees C)}
#'   \item{Water_temperature_4m}{Water temperature at 4 m depth (degrees C)}
#'   \item{Water_temperature_5m}{Water temperature at 5 m depth (degrees C)}
#'   \item{Water_temperature_6m}{Water temperature at 6 m depth (degrees C)}
#'   \item{Water_temperature_7m}{Water temperature at 7 m depth (degrees C)}
#'   \item{Water_temperature_8m}{Water temperature at 8 m depth (degrees C)}
#'   \item{Water_temperature_9m}{Water temperature at 9 m depth (degrees C)}
#'   \item{Water_temperature_10m}{Water temperature at 10 m depth (degrees C)}
#'   \item{Water_temperature_11m}{Water temperature at 11 m depth (degrees C)}
#'   \item{Air_Temperature}{Air temperature (degrees C)}
#'   \item{Pyranometer}{Incoming solar radiation}
#'   \item{Wind_Speed}{Wind speed}
#' }
#'
#' @references
#' Jones, I., & Feuchtmayr, H. (2017).
#' \emph{Data from automatic water monitoring buoy from Esthwaite Water,
#' 2008 to 2011}.
#' NERC Environmental Information Data Centre.
#' \doi{10.5285/94abcb39-84a6-428e-a90f-156452197d79}
#'
#' @source
#' \url{https://doi.org/10.5285/94abcb39-84a6-428e-a90f-156452197d79}
#'
"Esthwaite_Buoy_OLD"