function [abort]=LoopBreakerStim(P)
abort=0;
[keyIsDown, ~, keyCode] = KbCheck();
if keyIsDown
    if find(keyCode) == P.keys.name.esc
        abort=1;
    end
end
end