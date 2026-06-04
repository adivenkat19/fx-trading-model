% ═══════════════════════════════════════════════════════════════
%  backtest.m — Clean Final Version
% ═══════════════════════════════════════════════════════════════

% ── Parameters ────────────────────────────────────────────────
lotSize    = 10000;
currentPos = 0;

% ── Signal Loop ───────────────────────────────────────────────
n       = height(EURUSD);
signals = zeros(n,1);
trades  = zeros(n,1);

for i = 91:n
    signals(i) = myModel(EURUSD.Price(1:i));
    if signals(i) ~= currentPos
        trades(i)  = signals(i);
        currentPos = signals(i);
    end
end

% ── Trade Summary ─────────────────────────────────────────────
fprintf('\n════════════════════════════════════════\n')
fprintf('  5 YEAR BACKTEST — EUR/USD\n')
fprintf('════════════════════════════════════════\n')
fprintf('  Total trading days:  %d\n',   n)
fprintf('  Days Long:           %d (%.1f%%)\n', sum(signals==1),  sum(signals==1)/n*100)
fprintf('  Days Short:          %d (%.1f%%)\n', sum(signals==-1), sum(signals==-1)/n*100)
fprintf('  Days Flat:           %d (%.1f%%)\n', sum(signals==0),  sum(signals==0)/n*100)
fprintf('  ──────────────────────────────────────\n')
fprintf('  Total trades placed: %d\n',   sum(trades~=0))
fprintf('  Long  entries:       %d\n',   sum(trades==1))
fprintf('  Short entries:       %d\n',   sum(trades==-1))
fprintf('════════════════════════════════════════\n')

% ── Hit Rate ──────────────────────────────────────────────────
correct = 0;
wrong   = 0;

for i = 91:n-5
    if trades(i) ~= 0
        actualMove = EURUSD.Price(i+5) - EURUSD.Price(i);
        if trades(i) == 1 && actualMove > 0
            correct = correct + 1;
        elseif trades(i) == -1 && actualMove < 0
            correct = correct + 1;
        else
            wrong = wrong + 1;
        end
    end
end

totalTrades = correct + wrong;
hitRate     = (correct / totalTrades) * 100;

fprintf('\n════════════════════════════════════════\n')
fprintf('  SIGNAL ACCURACY\n')
fprintf('════════════════════════════════════════\n')
fprintf('  Total trades:   %d\n',          totalTrades)
fprintf('  Correct:        %d  (%.1f%%)\n', correct,  hitRate)
fprintf('  Wrong:          %d  (%.1f%%)\n', wrong,    100-hitRate)
if hitRate >= 60
    fprintf('  Rating:         EXCELLENT ★★★\n')
elseif hitRate >= 55
    fprintf('  Rating:         GOOD ★★\n')
elseif hitRate >= 50
    fprintf('  Rating:         ABOVE RANDOM ★\n')
else
    fprintf('  Rating:         NEEDS TUNING\n')
end
fprintf('════════════════════════════════════════\n')

% ── CHART 1: Price with Entry Points ──────────────────────────
figure;
plot(EURUSD.Date, EURUSD.Price, 'Color', [0.3 0.5 0.8], 'LineWidth', 1.2);
hold on;
plot(EURUSD.Date(trades==1),  EURUSD.Price(trades==1),  '^g', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(EURUSD.Date(trades==-1), EURUSD.Price(trades==-1), 'vr', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'r');
legend('EUR/USD Price', 'Go Long', 'Go Short', 'Location', 'northwest');
title('5 Year Backtest — Entry Points');
xlabel('Date'); ylabel('Price');
grid on;

% ── CHART 2: Signal Accuracy Bar ──────────────────────────────
figure;
b = bar([hitRate, 100-hitRate], 'FaceColor', 'flat');
b.CData(1,:) = [0 0.7 0];
b.CData(2,:) = [0.8 0 0];
set(gca, 'XTickLabel', {'Correct', 'Wrong'});
ylabel('Percentage (%)');
title(sprintf('Signal Accuracy: %.1f%% Hit Rate', hitRate));
ylim([0 110]);
grid on;
text(1, hitRate+3,     sprintf('%.1f%%', hitRate),     ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14)
text(2, 100-hitRate+3, sprintf('%.1f%%', 100-hitRate), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14)

% ── CHART 3: Signal Over Time ─────────────────────────────────
figure;
area(EURUSD.Date, signals, 'FaceColor', [0.2 0.6 0.9], 'FaceAlpha', 0.4);
ylim([-1.5 1.5]);
yticks([-1 0 1]);
yticklabels({'Short', 'Flat', 'Long'});
title('Model Position Over Time');
xlabel('Date');
grid on;

% ── P&L with Stop Loss + Take Profit ─────────────────────────
pnl        = zeros(n, 1);
pos        = 0;
entryPrice = 0;
stopLoss   = 0.005;    % 0.5% stop loss
takeProfit = 0.010;    % 1.0% take profit

for i = 91:n-1
    if signals(i) ~= pos
        pos        = signals(i);
        entryPrice = EURUSD.Price(i);
    end

    if pos ~= 0 && entryPrice ~= 0
        priceMovePC = pos * (EURUSD.Price(i) - entryPrice) / entryPrice;

        if priceMovePC <= -stopLoss
            pnl(i)     = -stopLoss * lotSize;
            pos        = 0;
            entryPrice = 0;
        elseif priceMovePC >= takeProfit
            pnl(i)     = takeProfit * lotSize;
            pos        = 0;
            entryPrice = 0;
        else
            pnl(i+1) = pos * (EURUSD.Price(i+1) - EURUSD.Price(i)) ...
                       / mean(EURUSD.Price) * lotSize;
        end
    end
end

% ── Equity Curve ──────────────────────────────────────────────
equityCurve = 10000 + cumsum(pnl);

% ── CHART 4: Equity Curve ─────────────────────────────────────
figure;
plot(EURUSD.Date, equityCurve, 'Color', [0.2 0.7 0.3], 'LineWidth', 1.5);
hold on;
yline(10000, '--r', 'Starting Capital', 'LineWidth', 1);
title('Equity Curve — 5 Year Strategy Performance');
xlabel('Date'); ylabel('Account Value ($)');
grid on;

% ── Sharpe + Sortino ──────────────────────────────────────────
dailyReturns    = diff(equityCurve) ./ equityCurve(1:end-1);
riskFreeDaily = 0.031 / 252;
excessReturns   = dailyReturns - riskFreeDaily;
sharpeRatio     = (mean(excessReturns) / std(excessReturns)) * sqrt(252);
downsideReturns = excessReturns(excessReturns < 0);
downsideStd     = std(downsideReturns) * sqrt(252);
sortinoRatio    = (mean(excessReturns) * 252) / downsideStd;

% ── Print Metrics ─────────────────────────────────────────────
fprintf('\n════════════════════════════════════════\n')
fprintf('  STRATEGY PERFORMANCE METRICS\n')
fprintf('════════════════════════════════════════\n')
fprintf('  Starting Capital:  $10,000\n')
fprintf('  Final Capital:     $%.2f\n',    equityCurve(end))
fprintf('  Total Return:      %.2f%%\n',   (equityCurve(end)-10000)/10000*100)
fprintf('  ──────────────────────────────────────\n')
fprintf('  Sharpe Ratio:      %.3f\n',     sharpeRatio)
fprintf('  Sortino Ratio:     %.3f\n',     sortinoRatio)
fprintf('  ──────────────────────────────────────\n')
if sharpeRatio > 2
    fprintf('  Sharpe Rating:     EXCELLENT ★★★\n')
elseif sharpeRatio > 1
    fprintf('  Sharpe Rating:     GOOD ★★\n')
elseif sharpeRatio > 0
    fprintf('  Sharpe Rating:     BELOW AVERAGE ★\n')
else
    fprintf('  Sharpe Rating:     POOR\n')
end
fprintf('════════════════════════════════════════\n')
