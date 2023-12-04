function [M_event, M_cycle, boi_mark, boi_loca] = boi_gen(signal, W_event, W_cycle, beta, is_thresholded)

M_event = movmean(signal, W_event);
M_cycle = movmean(signal, W_cycle) + beta * mean(signal, 2);
boi_mark = zeros(size(signal));
count = 0;
boi_loca = zeros(2, 1, 'uint32');
for i = 1:length(M_event)
    if M_event(1, i) >= M_cycle(1, i)
        boi_mark(1, i) = 1;
        if (i == 1)
            count = count + 1;
            boi_loca(1, count) = i;
            boi_loca(2, count) = length(signal);
        elseif (boi_mark(1, i - 1) == 0)
            count = count + 1;
            boi_loca(1, count) = i;
            boi_loca(2, count) = length(signal);
        end
    else
        if i ~= 1
            if boi_mark(1, i - 1) == 1
                boi_loca(2, count) = i - 1;
            end
        end
    end
end

% Thresholding with W_event
if is_thresholded
    i = 1;
    while (i <= length(boi_loca(1, :))) && ~isempty(boi_loca)
        if (boi_loca(2, i) - boi_loca(1, i)) < W_event
            boi_mark(1, boi_loca(1, i):boi_loca(2, i)) = zeros(1, boi_loca(2, i) - boi_loca(2, i) + 1);
            boi_loca(:, i) = [];
        else
            i = i + 1;
        end
    end
end

end