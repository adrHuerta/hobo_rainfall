rm(list = ls())
"%>%" = magrittr::`%>%`

# multiple files: each one has its own date format (see how to handle it)

hua1 <- read.csv("./data/new_data/Huancaro19.01.2020.csv",
                 header = FALSE,
                 skip = 2) %>%
  .[, c(2, 3)] %>%
  transform(date_time = as.POSIXct(V2, format = "%m/%d/%y %I:%M:%S %p"),
            count = V3) %>%
  .[c("date_time", "count")]

hua2 <- read.csv("./data/new_data/Huancaro23.02.2020.csv",
                 header = FALSE,
                 skip = 2) %>%
  .[, c(2, 3)]  %>%
  transform(date_time = as.POSIXct(V2, format = "%y-%m-%d %H:%M:%S"),
            count = V3) %>%
  .[c("date_time", "count")] %>%
  .[.$date_time > hua1$date_time[length(hua1$date_time)], ]

hua3 <- read.csv("./data/new_data/Huancaro08.03.2020.csv",
                 header = FALSE,
                 skip = 2) %>%
  .[, c(2, 3)] %>%
  transform(date_time = as.POSIXct(V2, format = "%y-%m-%d %H:%M:%S"),
            count = V3) %>%
  .[c("date_time", "count")] %>%
  .[.$date_time > hua2$date_time[length(hua2$date_time)], ]

hua4 <- read.csv("./data/new_data/Huancaro8_6_2020.csv",
                 header = FALSE,
                 skip = 2) %>%
  .[, c(2, 3)] %>%
  transform(date_time = as.POSIXct(V2, format = "%y-%m-%d %H:%M:%S"),
            count = V3) %>%
  .[c("date_time", "count")] %>%
  .[.$date_time > hua3$date_time[length(hua3$date_time)], ]

hua5 <- read.csv("./data/new_data/Huancaro27_10_2020.csv",
                 header = FALSE,
                 skip = 2) %>%
  .[, c(2, 3)] %>%
  transform(date_time = as.POSIXct(V2, format = "%Y-%m-%d %H:%M"),
            count = V3) %>%
  .[c("date_time", "count")] %>%
  .[.$date_time > hua4$date_time[length(hua4$date_time)], ]
 
hua1[433, "count"] <- NA
hua2[984, "count"] <- NA
hua3[177, "count"] <- NA
hua4[482, "count"] <- NA
hua5[147, "count"] <- NA

hobo <- rbind(hua1, hua2, hua3, hua4, hua5)
hobo <- hobo %>%
  transform(diff = c(0, diff(date_time, 1))) %>%
  transform(pp = ifelse(diff <= 1 | is.na(count), 0, 0.2))

hobo_minute <- xts::xts(hobo$pp, hobo$date_time) %>%
  xts::period.apply(x = .,
                    INDEX = xts::endpoints(., on = "minutes"),
                    FUN = sum)

zoo::index(hobo_minute) = as.POSIXct(paste(format(time(hobo_minute), "%Y-%m-%d %H:%M"), ":00", sep = ""))
xts_minute = seq(as.POSIXct("2019-12-26 00:00:00"), as.POSIXct("2020-10-27 23:00:00"), by = 60)
hobo_minute = merge(hobo_minute, xts_minute)
hobo_minute[is.na(hobo_minute)] = 0
hobo_minute[ time(hobo_minute) < hobo$date_time[1]] = NA
hobo_minute[ time(hobo_minute) > hobo$date_time[length(hobo$date_time)]] = NA

hobo_hourly <- xts::period.apply(x = hobo_minute,
                    INDEX = xts::endpoints(hobo_minute, on = "hours"),
                    FUN = sum)

zoo::index(hobo_hourly) = as.POSIXct(paste(format(time(hobo_hourly), "%Y-%m-%d %H"), ":00:00", sep = ""))

hobo_daily <- hobo_hourly %>%
  xts::lag.xts(., k = -8) %>% # daily sum as in a conventional station (PERU time 7am-7pm)
  xts::apply.daily(sum, na.rm = FALSE)
zoo::index(hobo_daily) = as.Date(format(time(hobo_daily), "%Y-%m-%d"))


# zoo::write.zoo(hobo_minute, "./data/hobo_minute.csv") file too big
zoo::write.zoo(hobo_hourly, "./data/hobo_hourly.csv")
zoo::write.zoo(hobo_daily, "./data/hobo_daily.csv")
