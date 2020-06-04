rm(list = ls())

"%>%" = magrittr::`%>%`

#### hobo dataset ####

hobo <- read.csv("./data/hobo_quincemil.csv", header = F) %>%
  setNames(c("date_time", "count")) %>%
  transform(date_time = strptime(date_time, "%m/%d/%Y %H:%M:%S")) %>%
  transform(diff = c(0, diff(date_time, 1))) %>%
  
  # Deleting (equal to 0) FALSE DOUBLES (differences in count less or equal to 1) and
  # LOGGED (NA values in count) date_times
  
  transform(pp = ifelse(diff <= 1 | is.na(count), 0, 0.2))

  # Deleting (equal to 0) events in days(hours) of INSTALLATION and DATA DOWNLOADING
  # This corresponds to the first and two last events, respectively 
  
hobo[c(1, 13918, 13919), "pp"] = 0

## hobo dataset to continuous date (to seconds and minute)
  
  # as no events is equal to 0, you could create a continuous date-time 
  # with all non numeric values to 0 OR interpolate the numeric values 
  # into the NA values (of the continuous date_time)

## hobo dataset to continuous date (to hours and daily)

hobo_hourly <- xts::xts(hobo$pp, hobo$date_time) %>%
  xts::period.apply(x = .,
                    INDEX = xts::endpoints(., on = "hours"),
                    FUN = sum)

# making minutes and seconds to 00
zoo::index(hobo_hourly) = as.POSIXct(paste(format(time(hobo_hourly), "%Y-%m-%d %H"), ":00:00", sep = ""))

# creating a continuous time span
xts_hourly = seq(as.POSIXct("2017-02-14 00:00:00"), as.POSIXct("2017-07-24 23:00:00"), by = 3600)

# converting irregular to regular xts ts
hobo_hourly = merge(hobo_hourly, xts_hourly)
hobo_hourly[is.na(hobo_hourly)] = 0


hobo_daily <- hobo_hourly %>%
  xts::lag.xts(., k = -8) %>% # daily sum as in a conventional station (PERU time 7am-7pm)
  xts::apply.daily(sum, na.rm = F)

# converting time to date
zoo::index(hobo_daily) = as.Date(format(time(hobo_daily), "%Y-%m-%d"))


#### conventional dataset ######

conventional <- read.csv("./data/conventional_quincemil.csv", header = F, na.strings = -999) %>%
  setNames(c("Y", "M", "D", "pp")) %>%
  transform(date_time = ISOdate(year = Y, month = M, day = D))

conventional_daily = xts::xts(conventional$pp, as.Date(conventional$date_time))


#### comparison ######

cbind(hobo_daily, conventional_daily) %>% 
  window(start = "2017-02-01", end = "2017-07-31") %>% 
  xts::plot.xts(col = c("royalblue", "black"), lwd = c(2, 3.5), lty = c(1, 1))

xts::addLegend("top", on = 1,
               legend.names = c("hobo_daily", "conventional_daily"),
               lwd = c(2, 3.5),
               col = c("royalblue", "black"),
               cex = 1)

cor(cbind(hobo_daily, conventional_daily) %>% zoo::coredata(),
    use = "pairwise.complete.obs",
    method = "spearman")

(hobo_daily-conventional_daily) %>%
  .[!is.na(.)] %>%
  mean()
