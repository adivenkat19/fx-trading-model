function [returns, sharpe] = backtester(prices, Q, R)
% Backtester
%
% prices (closing prices only)
% Q, R(Kalman parameters)
% returns  (daily relative returns vector)
% sharpe  (Sharpe ratio)

n       = length(prices);
returns = zeros(n, 1);

for i = 2:n
    pos = myModel(prices(1:i-1), Q, R);

    returns(i) = pos * (prices(i) - prices(i-1)) / prices(i-1);
end

% Sharpe ratio
rfDaily = 0.031 / 252;
excess  = returns - rfDaily;

if std(excess) < 1e-10
    sharpe = 0;
else
    sharpe = (mean(excess) / std(excess)) * sqrt(252);
end

end
