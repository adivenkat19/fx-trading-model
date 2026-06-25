% surfPlot.m
% 10x10 grid of Q and R values
% Plots 3D Sharpe surface

prices = EURUSD.Price;


Q_values = logspace(-6, -4, 10);
R_values = logspace(-4, -2, 10);

sharpeMatrix = zeros(10, 10);

fprintf('Running 100 combinations...\n')

for i = 1:10
    for j = 1:10
        [~, sharpeMatrix(i,j)] = backtester(prices, Q_values(i), R_values(j));
        fprintf('Q=%d R=%d Sharpe=%.3f\n', i, j, sharpeMatrix(i,j))
    end
end

% 3D surface plot
figure;
surf(log10(Q_values), log10(R_values), sharpeMatrix);
xlabel('Q (log10)');
ylabel('R (log10)');
zlabel('Sharpe Ratio');
title('Kalman Parameter Space — Sharpe Surface');
colorbar;
grid on;
