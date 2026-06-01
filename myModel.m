function position = myModel(prices)
% ═══════════════════════════════════════════════════════════════
%  Trading Model: Kalman Filter + Markov Chain + ARIMA (AR3)
%
%  Strategy: Weighted consensus of 3 independent signals
%  Weights:  Kalman=1.0, Markov=0.8, ARIMA=0.7 (total max=2.5)
%  Threshold: score must exceed ±1.8 to take a position
%
%  Input:  prices → array of daily closing prices
%  Output: position → 1 (Long), -1 (Short), 0 (Flat)
% ═══════════════════════════════════════════════════════════════

    % ── Minimum data requirement ──────────────────────────
    if length(prices) < 90
        position = 0;
        return;
    end

    % ══════════════════════════════════════════════════════
    %  SIGNAL 1 — KALMAN FILTER (weight = 1.0)
    %  Estimates true underlying trend beneath price noise
    % ══════════════════════════════════════════════════════
    Q = 1e-5;    % process noise: how fast the true trend changes
    R = 1e-3;    % measurement noise: how noisy raw prices are

    x = prices(max(1,end-90));
    P = 1;
    filtered = zeros(length(prices), 1);

    for i = 1:length(prices)
        % Predict step
        x_pred = x;
        P_pred = P + Q;
        % Update step
        K      = P_pred / (P_pred + R);   % Kalman gain
        x      = x_pred + K * (prices(i) - x_pred);
        P      = (1 - K) * P_pred;
        filtered(i) = x;
    end

    % Trend = slope of filtered price over last 5 days
    trendSlope = filtered(end) - filtered(end-5);

    % Strict threshold: must move more than 0.0003 to signal
    if trendSlope > 0.0003
        kalmanSignal = 1;
    elseif trendSlope < -0.0003
        kalmanSignal = -1;
    else
        kalmanSignal = 0;
    end

    % ══════════════════════════════════════════════════════
    %  SIGNAL 2 — MARKOV CHAIN (weight = 0.8)
    %  Uses historical transition probabilities to predict
    %  whether price is more likely to go Up or Down next
    % ══════════════════════════════════════════════════════
    if length(prices) < 91
        position = 0;
        return;
    end
    returns = diff(prices(end-90:end));

    threshold = std(returns) * 0.1;

    % Label each day: 1=Up, 2=Flat, 3=Down
    states = 2 * ones(length(returns), 1);   % default Flat
    states(returns >  threshold) = 1;         % Up
    states(returns < -threshold) = 3;         % Down

    % Build 3x3 transition matrix with Laplace smoothing
    T = ones(3, 3) * 0.001;
    for i = 1:length(states)-1
        T(states(i), states(i+1)) = T(states(i), states(i+1)) + 1;
    end
    T = T ./ sum(T, 2);   % normalize rows to probabilities

    % Current state → look up transition probabilities
    currentState = states(end);
    pUp   = T(currentState, 1);   % prob next day is Up
    pDown = T(currentState, 3);   % prob next day is Down

    % Strict margin: pUp must beat pDown by at least 20%
    if pUp > pDown + 0.20
        markovSignal = 1;
    elseif pDown > pUp + 0.20
        markovSignal = -1;
    else
        markovSignal = 0;
    end

    % ══════════════════════════════════════════════════════
    %  SIGNAL 3 — ARIMA / AR(3) FORECAST (weight = 0.7)
    %  Fits autoregressive model to predict tomorrow's price
    %  Uses differenced series to ensure stationarity
    % ══════════════════════════════════════════════════════
    dPrices = diff(prices);   % first difference (the I in ARIMA)

    % Use last 20 observations for AR(3) fit
    window = min(30, length(dPrices) - 3);
    y = dPrices(end-window-2:end);

    % Build lagged regression matrix
    Y = y(4:end);
    X = [y(3:end-1), y(2:end-2), y(1:end-3)];

    % Least squares: fit AR(3) coefficients
    if size(X,1) >= 3 && rank(X) == size(X,2)
        coeffs = X \ Y;
    else
        coeffs = [0.3; 0.2; 0.1];   % sensible fallback
    end

    % Forecast next day's price change
    forecastChange = coeffs(1) * dPrices(end)   + ...
                     coeffs(2) * dPrices(end-1) + ...
                     coeffs(3) * dPrices(end-2);

    forecastPrice = prices(end) + forecastChange;

    % Strict threshold: needs 0.05% predicted move to signal
    if forecastPrice > prices(end) * 1.0005
        arimaSignal = 1;
    elseif forecastPrice < prices(end) * 0.9995
        arimaSignal = -1;
    else
        arimaSignal = 0;
    end

    % ══════════════════════════════════════════════════════
    %  COMBINE — WEIGHTED VOTE (threshold = ±1.8 out of 2.5)
    %  Kalman has most weight as most mathematically robust
    %  Need strong consensus to avoid overtrading
    % ══════════════════════════════════════════════════════
    weightedScore = (kalmanSignal * 1.0) + ...
                    (markovSignal * 0.8) + ...
                    (arimaSignal  * 0.7);

    if weightedScore >= 1.6
        position = 1;    % strong bullish consensus → Long
    elseif weightedScore <= -1.6
        position = -1;   % strong bearish consensus → Short
    else
        position = 0;    % insufficient consensus  → Flat
    end

end
