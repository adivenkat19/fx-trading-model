# Kalman Filter Trading System

## What This Does

This is a trend-following trading strategy built around a Kalman Filter. The idea is simple — use the Kalman Filter to smooth out noisy price data, then trade in the direction of the trend. To figure out the best filter settings, we run 100 different parameter combinations and plot the results as a 3D surface so we can visually see which settings work best.

---

## How the Pieces Fit Together

```
kalmanFilter.m   →   smooths raw prices
      ↓
myModel.m        →   generates signal (-1, 0, +1)
      ↓
backtester.m     →   calculates returns and Sharpe Ratio
      ↓
surfPlot.m       →   runs all 100 combinations and plots the surface
```

---

## kalmanFilter.m

Takes in a price series and two parameters (Q and R) and returns a smoothed version of the prices.

**Inputs:**
- `prices` — closing prices
- `Q` — process noise (how fast the filter reacts to new trends)
- `R` — measurement noise (how much it trusts raw prices vs its own estimate)

**Output:**
- `filtered` — smoothed price series

**How it works:**
The filter keeps a running estimate of the "true" price and updates it each day based on how noisy it thinks the market is. Small Q + large R means it updates slowly and stays smooth. Large Q + small R means it reacts quickly to price moves.

---

## myModel.m

Calls the Kalman Filter and decides whether to go long, short, or flat based on the slope of the filtered prices over the last 5 days.

**Inputs:**
- `prices` — closing prices up to current day
- `Q`, `R` — passed straight to the Kalman Filter

**Output:**
- `position` — +1 (long), -1 (short), 0 (flat)

**Logic:**
- Returns 0 if there are fewer than 10 prices (not enough history yet)
- If filtered price slope is positive → long (+1)
- If filtered price slope is negative → short (-1)
- If flat → no position (0)

---

## backtester.m

Simulates trading day by day using the signals from myModel and calculates how the strategy performed.

**Inputs:**
- `prices` — full closing price series
- `Q`, `R` — Kalman parameters

**Outputs:**
- `returns` — vector of daily relative returns
- `sharpe` — annualized Sharpe Ratio

**P&L logic:**
Each day, we look at yesterday's signal and apply it to today's price move:
```
return(i) = position × (price(i) - price(i-1)) / price(i-1)
```

**Sharpe Ratio:**
```
risk-free rate = 3.1% / 252 (daily)
sharpe = (mean(excess returns) / std(excess returns)) × sqrt(252)
```

---

## surfPlot.m

Runs the full 100 combination grid search and plots the results as a 3D surface.

**What it does:**
- Tests 10 values of Q (1e-6 to 1e-4, log-spaced)
- Tests 10 values of R (1e-4 to 1e-2, log-spaced)
- Calls backtester for each combination → stores Sharpe in a 10x10 matrix
- Plots a 3D surface: X = log10(Q), Y = log10(R), Z = Sharpe Ratio

**The goal:**
We're not looking for one perfect point — we're looking for a **region** of good parameters. A patch of high Sharpe values means the strategy works consistently across nearby settings, which is more trustworthy than a single spike.

---

## How to Run

1. Load EUR/USD data into MATLAB as `EURUSD` with a `.Price` column
2. Make sure all four `.m` files are in the same folder
3. Run `surfPlot.m`
4. Watch the 100 combinations print and the surface plot appear

---

*Written June 2026*
