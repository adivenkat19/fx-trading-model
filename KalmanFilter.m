function filtered = kalmanFilter(prices, Q, R)
% Kalman Filter
% prices(closing prices)
% Q(process noise (how fast trend changes))
% R(measurement noise (how noisy prices are)
% filtered(smoothed price estimate)

n        = length(prices);
filtered = zeros(n, 1);
x        = prices(1);
P        = 1;

for i = 1:n
    P = P + Q;
    K           = P / (P + R);
    x           = x + K * (prices(i) - x);
    P           = (1 - K) * P;
    filtered(i) = x;
end 

end
