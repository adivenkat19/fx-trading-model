function position = myModel(prices, Q, R)
% Trading signal using Kalman Filter
% prices(closing prices)
% Q, R(Kalman parameters)
% position - 1 (long), -1 (short), 0 (flat)

    if length(prices) < 10
        position = 0;
        return;
    end

    filtered = kalmanFilter(prices, Q, R);

    slope = filtered(end) - filtered(end-5);

    if slope > 0
        position = 1;
    elseif slope < 0
        position = -1;
    else
        position = 0;
    end

end
