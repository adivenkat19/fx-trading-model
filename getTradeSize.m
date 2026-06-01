function [tradeSize, tradeDirection, tradeNote] = getTradeSize(currentPos, requiredPos, lotSize)
% ═══════════════════════════════════════════════════════════════
%  Position Reconciliation + Trade Sizing
%
%  Inputs:
%    currentPos  → your current position  (-1, 0, or +1)
%    requiredPos → what myModel() returned (-1, 0, or +1)
%    lotSize     → base trade size in currency units
%                  e.g. 10000 means €10,000 per unit
%
%  Outputs:
%    tradeSize      → units to trade (0, lotSize, or 2x lotSize)
%    tradeDirection → 'BUY', 'SELL', or 'NONE'
%    tradeNote      → plain English explanation of what happened
%
%  Position Change Rules:
%    Flat   → Long  : BUY  1x  (open long)
%    Flat   → Short : SELL 1x  (open short)
%    Long   → Flat  : SELL 1x  (close long)
%    Short  → Flat  : BUY  1x  (close short)
%    Long   → Short : SELL 2x  (close long + open short)
%    Short  → Long  : BUY  2x  (close short + open long)
%    Same   → Same  : NONE 0   (do nothing)
% ═══════════════════════════════════════════════════════════════

posChange = requiredPos - currentPos;

switch posChange
    case 0
        % Already in required position
        tradeSize      = 0;
        tradeDirection = 'NONE';
        tradeNote      = 'No trade needed — already in required position';

    case 1
        % Flat→Long or Short→Flat
        tradeSize      = lotSize;
        tradeDirection = 'BUY';
        if currentPos == 0
            tradeNote  = sprintf('Opening LONG position: BUY €%d', lotSize);
        else
            tradeNote  = sprintf('Closing SHORT position: BUY €%d', lotSize);
        end

    case -1
        % Flat→Short or Long→Flat
        tradeSize      = lotSize;
        tradeDirection = 'SELL';
        if currentPos == 0
            tradeNote  = sprintf('Opening SHORT position: SELL €%d', lotSize);
        else
            tradeNote  = sprintf('Closing LONG position: SELL €%d', lotSize);
        end

    case 2
        % Short→Long: must close short AND open long = 2x
        tradeSize      = 2 * lotSize;
        tradeDirection = 'BUY';
        tradeNote      = sprintf('Reversing SHORT→LONG: BUY €%d (2x)', 2*lotSize);

    case -2
        % Long→Short: must close long AND open short = 2x
        tradeSize      = 2 * lotSize;
        tradeDirection = 'SELL';
        tradeNote      = sprintf('Reversing LONG→SHORT: SELL €%d (2x)', 2*lotSize);

    otherwise
        tradeSize      = 0;
        tradeDirection = 'NONE';
        tradeNote      = 'ERROR: Invalid position values';
end

end
