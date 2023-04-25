# Time Series Analysis

## Analysis and Prediction of BHP Stocks Price in R

Data collected in a chronological sequence is known as time-series data. Often, it is gathered at regular intervals, such as daily, monthly, or annually. By plotting this type of data, patterns such as trends, seasonality, or a mix of both can be observed. Recognizing these patterns can aid in decision-making. For instance, discerning a seasonal pattern in stock prices can help determine the optimal times to buy or sell shares. In R, data decomposition allows for a more detailed examination of these patterns.

### Data:

In R, the <code>quantmod</code> package makes it simple to acquire stock prices. This package caters to quantitative traders, helping them effortlessly explore and develop trading models. It relies on Yahoo Finance for stock price data, so it's essential to verify your stock's ticker on Yahoo Finance before using this package. In this example, we'll analyze the stock price of BHP Mining (BHP.AX) from 2015 to  the end of 2021.

We can check for null values (non-trading days)and also remove outliers (extreme lows or highs). One common method for detecting outliers is usign IQR (Interquartile Range).

The data we've gathered consists of daily OHLC (Open, High, Low, Close) values. For our analysis, we'll focus on the closing price, which can be extracted using the <code>Cl()</code> function. Closing prices are deemed valuable indicators for evaluating fluctuations in stock prices over time. Some investors, however, prefer using adjusted prices instead of closing prices.

### Visualization:
Stock price data can be visualized through static or interactive plots. By doing so, we can examine the data patterns and understand how they may influence our investment decisions.


In general, the plot reveals an upward trend and seasonal patterns. To further examine the data components, we will decompose it. Our focus will be on the closing price, and we will initially convert the periods to monthly data.
