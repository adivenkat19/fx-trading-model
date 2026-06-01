% ═══════════════════════════════════════════════════════════════
%  backtest.m
%  Full 5-Year Backtest — EUR/USD
%  Includes: signal loop, trade counter, hit rate, both charts
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

    % Only record a trade when signal CHANGES
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

% ── Hit Rate Calculation ──────────────────────────────────────
correct = 0;
wrong   = 0;

for i = 91:n-5
    if trades(i) ~= 0
        % Check price move over NEXT 5 days instead of just 1
        actualMove = EURUSD.Price(i+5) - EURUSD.Price(i);

        if trades(i) == 1 && actualMove > 0
            correct = correct + 1;   % went Long, price went Up ✓
        elseif trades(i) == -1 && actualMove < 0
            correct = correct + 1;   % went Short, price went Down ✓
        else
            wrong = wrong + 1;       % wrong direction ✗
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

% ── CHART 1: Price with Entry Points ─────────────────────────
figure;
plot(EURUSD.Date, EURUSD.Price, 'Color', [0.3 0.5 0.8], 'LineWidth', 1.2);
hold on;
plot(EURUSD.Date(trades==1),  EURUSD.Price(trades==1),  '^g', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(EURUSD.Date(trades==-1), EURUSD.Price(trades==-1), 'vr', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'r');
legend('EUR/USD Price', 'Go Long', 'Go Short', 'Location', 'northwest');
title('5 Year Backtest — Entry Points (Kalman + Markov + ARIMA)');
xlabel('Date'); ylabel('Price');
grid on;

% ── CHART 2: Signal Accuracy Bar Chart ───────────────────────
figure;
b = bar([hitRate, 100-hitRate], 'FaceColor', 'flat');
b.CData(1,:) = [0 0.7 0];     % green for correct
b.CData(2,:) = [0.8 0 0];     % red for wrong
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
area(EURUSD.Date, signals, ...
    'FaceColor', [0.2 0.6 0.9], 'FaceAlpha', 0.4);
ylim([-1.5 1.5]);
yticks([-1 0 1]);
yticklabels({'Short', 'Flat', 'Long'});
title('Model Position Over Time');
xlabel('Date');
grid on;
