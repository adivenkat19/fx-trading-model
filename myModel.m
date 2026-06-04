function position = myModel(prices)
% Kalman + Markov + ARIMA — original working version

    if length(prices) < 91
        position = 0;
        return;
    end

    % KALMAN
    Q = 1e-5; R = 1e-3;
    x = prices(max(1,end-90));
    P = 1;
    filtered = zeros(length(prices),1);
    for i = 1:length(prices)
        x_pred = x;
        P_pred = P + Q;
        K      = P_pred / (P_pred + R);
        x      = x_pred + K * (prices(i) - x_pred);
        P      = (1 - K) * P_pred;
        filtered(i) = x;
    end
    trendSlope = filtered(end) - filtered(end-5);
    if trendSlope > 0.0003
        kalmanSignal = 1;
    elseif trendSlope < -0.0003
        kalmanSignal = -1;
    else
        kalmanSignal = 0;
    end

    % MARKOV
    returns   = diff(prices(end-90:end));
    threshold = std(returns) * 0.1;
    states    = 2 * ones(length(returns), 1);
    states(returns >  threshold) = 1;
    states(returns < -threshold) = 3;
    T = ones(3,3) * 0.001;
    for i = 1:length(states)-1
        T(states(i), states(i+1)) = T(states(i), states(i+1)) + 1;
    end
    T = T ./ sum(T, 2);
    currentState = states(end);
    pUp   = T(currentState, 1);
    pDown = T(currentState, 3);
    if pUp > pDown + 0.20
        markovSignal = 1;
    elseif pDown > pUp + 0.20
        markovSignal = -1;
    else
        markovSignal = 0;
    end

    % ARIMA
    dPrices = diff(prices);
    window  = min(30, length(dPrices) - 3);
    y = dPrices(end-window-2:end);
    Y = y(4:end);
    X = [y(3:end-1), y(2:end-2), y(1:end-3)];
    if size(X,1) >= 3 && rank(X) == size(X,2)
        coeffs = X \ Y;
    else
        coeffs = [0.3; 0.2; 0.1];
    end
    forecastChange = coeffs(1)*dPrices(end) + ...
                     coeffs(2)*dPrices(end-1) + ...
                     coeffs(3)*dPrices(end-2);
    forecastPrice  = prices(end) + forecastChange;
    if forecastPrice > prices(end) * 1.0005
        arimaSignal = 1;
    elseif forecastPrice < prices(end) * 0.9995
        arimaSignal = -1;
    else
        arimaSignal = 0;
    end

    % COMBINE
    weightedScore = (kalmanSignal * 1.0) + ...
                    (markovSignal * 0.8) + ...
                    (arimaSignal  * 0.7);
    if weightedScore >= 1.6
        position = 1;
    elseif weightedScore <= -1.6
        position = -1;
    else
        position = 0;
    end

end
