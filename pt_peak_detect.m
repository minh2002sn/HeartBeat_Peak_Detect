function [P, T] = pt_peak_detect(ecg, R, fs, is_plotting_p, is_plotting_t)

P = zeros(1, 1, 'uint32');
T = zeros(1, 1, 'uint32');

% Get R peak free signal
ecg_r_peak_free = ecg;
before_interval = round(0.083*fs);
after_interval = round(0.167*fs);
ecg_r_peak_free(1, (R - before_interval):(R + after_interval)) = zeros(1, after_interval + before_interval + 1);

% Detect block of interest (BOI)
beta = 0.1;
W_event = round(0.05 * fs); % = half P wave
if mod(W_event, 2) == 0
    W_event = W_event - 1;
end
W_cycle = round(0.7 * fs); % = ECG duration
if mod(W_cycle, 2) == 0
    W_cycle = W_cycle + 1;
end
[M_event, M_cycle, p_boi_mark, p_peak_loca] = boi_gen(ecg_r_peak_free, W_event, W_cycle, beta);

% P peak detecting
for i = 1:length(p_peak_loca(1, :))
    [~, P(1, i)] = max(ecg_r_peak_free(1, p_peak_loca(1, i):p_peak_loca(2, i)));
    P(1, i) = P(1, i) + p_peak_loca(1, i) - 1;
end

% Thresholding P peaks with PR interval
PR_high_threshold = 0.2 * fs;
PR_low_threshold = 0.1 * fs;
p_index = 1;
t_index = 1;
while (p_index <= length(P)) && ~isempty(P)
    PR_temp = R - P(1, p_index);
    if (PR_temp <= 0) || (PR_temp > PR_high_threshold) || (PR_temp < PR_low_threshold)
        T(:, t_index) = P(:, p_index);
        t_index = t_index + 1;
        p_peak_loca(:, p_index) = [];
        P(:, p_index) = [];
    else
        p_index = p_index + 1;
    end
end
% Find max in remain P peak to get actual P peak
if ~isempty(P)
    P = P(ecg_r_peak_free(P) == max(ecg_r_peak_free(P)));
end

% Thresholding T peaks with RT interval
RT_high_threshold = 0.4 * fs;
RT_low_threshold = 0.1 * fs;
t_index = 1;
while (t_index <= length(T))  && ~isempty(T)
    RT_temp = T(1, t_index) - R;
    if (RT_temp <= 0) || (RT_temp > RT_high_threshold) || (RT_temp < RT_low_threshold)
        T(:, t_index) = [];
    else
        t_index = t_index + 1;
    end
end
% Find max in remain peak to get actual T peak
if ~isempty(T)
    T = T(ecg_r_peak_free(T) == max(ecg_r_peak_free(T)));
end

% Ploting P peak and T peak
if is_plotting_p || is_plotting_t
    t = 0:(length(ecg) - 1);
    figure('Name', "P and T peaks detection");
    subplot(3, 1, 1);
    plot(t, ecg_r_peak_free);
    subplot(3, 1, 2);
    hold on;
    plot(t, ecg_r_peak_free, 'k');
    plot(t, M_event, 'b');
    plot(t, M_cycle, 'r');
    plot(t, p_boi_mark, 'g');
    subplot(3, 1, 3);
    hold on;
    plot(t, ecg);
    if is_plotting_p
        plot(P, ecg(P), '^b', 'LineWidth', 2);
    end
    if is_plotting_t
        plot(T, ecg(T), 'sk', 'LineWidth', 2);
    end
end

end

