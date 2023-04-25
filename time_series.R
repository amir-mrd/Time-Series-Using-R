# installing and loading packages

library(ggplot2)
library(quantmod)
library(forecast)
library(highcharter)
library(PerformanceAnalytics)

# Retrieving BHP stocks price from Yahoo
symbol <- "BHP.AX"
start_date <- as.Date("2015-01-01") # Replace with the desired start date
end_date <- as.Date("2021-12-31") # Replace with the desired end date
prices <- getSymbols(symbol, src = "yahoo", from = start_date, to = end_date, auto.assign = FALSE)
prices <- data.frame(Date=index(prices), coredata(prices))


# Cheking for NaN values
any_na_bhp <- any(is.na(BHP.AX))
print(any_na_bhp)


# Checking for outliers:
price_changes <- diff(log(prices$BHP.AX.Close))
price_changes <- na.omit(price_changes)

quantile_25 <- quantile(price_changes, 0.25)
quantile_75 <- quantile(price_changes, 0.75)
IQR <- quantile_75 - quantile_25
lower_bound <- quantile_25 - 1.5 * IQR
upper_bound <- quantile_75 + 1.5 * IQR
outliers <- price_changes[price_changes < lower_bound | price_changes > upper_bound]

# Plotting the closed prices with identified outliers:
price_changes_df <- data.frame(Date = index(price_changes), PriceChange = price_changes)
ggplot(price_changes_df, aes(x = Date, y = PriceChange)) +
  geom_point() +
  geom_point(data = subset(price_changes_df, PriceChange < lower_bound | PriceChange > upper_bound), color = "red") +
  geom_hline(yintercept = c(lower_bound, upper_bound), linetype = "dashed", color = "blue") +
  labs(title = "BHP.AX Closing Price Percentage Changes with Outliers", x = "Date", y = "Price Change") +
  theme_minimal()

# Removing the outliers:
outlier_indices <- which(price_changes < lower_bound | price_changes > upper_bound)
BHP_clean <- prices[-c(outlier_indices, outlier_indices + 1), ]
price_changes_clean <- price_changes[-outlier_indices]


# Plotting the BHP Price:
chartSeries(BHP_clean, name = "BHP Price 2015-2021")
candleChart(BHP_clean, name = "BHP Price 2015-2021",
            theme = chartTheme("white", # Use a white background theme
                               up.col = "darkgreen", # Set custom colors for the candlestick chart
                               dn.col = "darkred",
                               up.border = "darkgreen",
                               dn.border = "darkred"),
            multi.col = TRUE, # Enable custom colors
            TA = "addSMA(n = 50, col = 'blue'); addSMA(n = 200, col = 'red')") # Add moving averages


# Take only the closing price
closing_pr <- Cl(to.monthly(BHP.AX))
dc <- decompose(as.ts(closing_pr, start=c(2015,1)))
plot(dc)

# Seasonal component 
dc$seasonal

## Interactive Plot
highchart(type="stock") %>% 
  hc_add_series(BHP.AX) %>% 
  hc_add_series(SMA(na.omit(Cl(bhp)),n=50),name="SMA(50)") %>% 
  hc_add_series(SMA(na.omit(Cl(bhp)),n=200),name="SMA(200)") %>% 
  hc_title(text="<b>BHP Price Candle Stick Chart 2015-2021</b>")

# Compaaring BHP stocks price with other mining giants:
bhp <- getSymbols("BHP.AX",auto.assign=FALSE,from=start_date,to=end_date)

# Rio Tinto
rio <- getSymbols("RIO.AX",auto.assign=FALSE,from=start_date,to=end_date)

# Fortescue Metals Group
fmg <- getSymbols("FMG.AX",auto.assign=FALSE,from=start_date,to=end_date)

#Newcrest Mining Limited
ncm <- getSymbols("NCM.AX",auto.assign=FALSE,from=start_date,to=end_date)

# Compare the stock prices
highchart(type="stock") %>% 
  hc_add_series(Cl(bhp), name="BHP") %>% 
  hc_add_series(Cl(rio), name="RIO") %>% 
  hc_add_series(Cl(fmg), name="FMG") %>% 
  hc_add_series(Cl(ncm), name="NCM") %>% 
  hc_title(text="<b>BHP vs RIO vs FMG vs NCM Closing Price</b>")

# Calculate the stocks return
return_bhp <- dailyReturn(Cl(bhp))
return_rio <- dailyReturn(Cl(rio))
return_fmg <- dailyReturn(Cl(fmg))
return_ncm <- dailyReturn(Cl(ncm))

# Combine the returns as one data frame
returns <- data.frame(return_bhp, return_rio,  return_fmg, return_ncm)
names(returns) <- c("BHP Return","RIO Return","FMG Return", "NCM Return")
returns <- as.xts(returns)

charts.PerformanceSummary(returns,main="Daily Return BHP vs RIO vs FMG vs NCM 2015-2021")

# Forecasting:

## Naive Forecasting:

n <- 100
train <- head(Cl(BHP.AX), length(Cl(BHP.AX))-n)
test <- tail(Cl(BHP.AX), n)
fc_na <- naive(train, h=n)

# Convert the train and test series into xts objects
train_xts <- xts(train, order.by = index(train))
test_xts <- xts(test, order.by = index(test))

# Create the index for the fc_na_xts object
forecast_start_date <- index(test_xts)[1]
forecast_end_date <- as.Date(index(train_xts)[length(train_xts)]) + (n * 2) # Extend the forecast range to account for non-trading days
forecast_dates <- seq(forecast_start_date, forecast_end_date, by = "days")

# Filter out the non-trading days from the forecast_dates
forecast_dates <- forecast_dates[forecast_dates %in% index(test_xts)]

# Convert the fc_na series into an xts object with the created index
fc_na_xts <- xts(fc_na$mean, order.by = forecast_dates)

# Convert the xts objects to data frames for plotting
train_df <- data.frame(Date = index(train_xts), Price = coredata(train_xts), Type = "Train")
test_df <- data.frame(Date = index(test_xts), Price = coredata(test_xts), Type = "Test")
fc_na_df <- data.frame(Date = index(fc_na_xts), Price = coredata(fc_na_xts), Type = "Naive Forecast")

# Ensure column names match
colnames(train_df) <- c("Date", "Price", "Type")
colnames(test_df) <- c("Date", "Price", "Type")
colnames(fc_na_df) <- c("Date", "Price", "Type")

# Combine the data frames
combined_df <- rbind(train_df, test_df, fc_na_df)

# Create the plot
ggplot(data = combined_df, aes(x = Date, y = Price, color = Type)) +
  geom_line() +
  ggtitle("Naive Forecast") +
  xlab("Time") +
  ylab("Price (AUD)") +
  scale_color_manual(values = c("Train" = "black", "Test" = "blue", "Naive Forecast" = "red"))

##ARIMA Model:
# Create the Model
model_non <- auto.arima(train, seasonal=FALSE)

# Forecast n periods of the data
fc_non <- forecast(model_non, h=n)

# Convert the train and test series into xts objects
train_xts <- xts(train, order.by = index(train))
test_xts <- xts(test, order.by = index(test))

# Create the index for the fc_na_xts object
forecast_start_date <- index(test_xts)[1]
forecast_end_date <- as.Date(index(train_xts)[length(train_xts)]) + (n * 2) # Extend the forecast range to account for non-trading days
forecast_dates <- seq(forecast_start_date, forecast_end_date, by = "days")

# Filter out the non-trading days from the forecast_dates
forecast_dates <- forecast_dates[forecast_dates %in% index(test_xts)]

# Convert the fc_na series into an xts object with the created index
fc_non_xts <- xts(fc_non$mean, order.by = forecast_dates)

# Convert the xts objects to data frames for plotting
train_df <- data.frame(Date = index(train_xts), Price = coredata(train_xts), Type = "Train")
test_df <- data.frame(Date = index(test_xts), Price = coredata(test_xts), Type = "Test")
fc_non_df <- data.frame(Date = index(fc_non_xts), Price = coredata(fc_non_xts), Type = "ARIMA Forecast")

# Ensure column names match
colnames(train_df) <- c("Date", "Price", "Type")
colnames(test_df) <- c("Date", "Price", "Type")
colnames(fc_non_df) <- c("Date", "Price", "Type")

# Combine the data frames
combined_df <- rbind(train_df, test_df, fc_non_df)

# Create the plot
ggplot(data = combined_df, aes(x = Date, y = Price, color = Type)) +
  geom_line() +
  ggtitle("ARIMA Forecast") +
  xlab("Time") +
  ylab("Price (AUD)") +
  scale_color_manual(values = c("Train" = "black", "Test" = "blue", "ARIMA Forecast" = "red"))

# Residuals
checkresiduals(fc_na)

checkresiduals(fc_non)

accuracy(fc_na)

accuracy(fc_non)

