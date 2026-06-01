% ═══════════════════════════════════════════════════════════════
%  runStrategy.m
%  Main script — connects myModel + getTradeSize together
%  Run this to execute the full trading strategy
% ═══════════════════════════════════════════════════════════════

% ── Configurable Parameters ───────────────────────────────────
lotSize    = 10000;   % € per trade — change this as needed
currentPos = 0;       % starting position (0 = flat)

% ── Step 1: Get signal from model ─────────────────────────────
requiredPos = myModel(EURUSD.Price);

% ── Step 2: Get trade instruction ─────────────────────────────
[tradeSize, tradeDirection, tradeNote] = getTradeSize(currentPos, requiredPos, lotSize);

% ── Step 3: Print results ──────────────────────────────────────
fprintf('\n════════════════════════════════\n')
fprintf(' STRATEGY RESULTS — EUR/USD\n')
fprintf('════════════════════════════════\n')
fprintf(' Model Signal:     %d\n',  requiredPos)
fprintf(' Trade Direction:  %s\n',  tradeDirection)
fprintf(' Trade Size:       €%d\n', tradeSize)
fprintf(' Action:           %s\n',  tradeNote)
fprintf('════════════════════════════════\n\n')

% ── Step 4: Update position ────────────────────────────────────
currentPos = requiredPos;
