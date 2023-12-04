function [P] = p_peak_detect(ecg_r_peak_free, fs, R, is_plotting)

P = zeros(1, 1, 'double');
% T = zeros(1, 1, 'double');

% Fractional Fourier Transfrorm and squaring
% enhanced_ecg = (abs(frft(ecg_r_peak_free, 0.01))*10).^2;
enhanced_ecg = (abs(ecg_r_peak_free)*10).^2;
% enhanced_ecg = (abs(ecg_r_peak_free) + 1).^2;
% enhanced_ecg = ecg_r_peak_free;
% figure
% subplot(2, 1, 1);
% plot(ecg_r_peak_free);
% subplot(2, 1, 2);
% plot(enhanced_ecg)
% figure
% cwt(ecg_r_peak_free);

% Detect block of interest (BOI)
beta = 0.1;
W_event = round(0.075 * fs); % = P wave
if mod(W_event, 2) == 0
    W_event = W_event - 1;
end
W_cycle = 0.7 * fs; % = ECG duration
if mod(W_cycle, 2) == 0
    W_cycle = W_cycle + 1;
end
[M_event, M_cycle, p_boi_mark, p_peak_loca] = boi_gen(enhanced_ecg, W_event, W_cycle, beta);

% P peak detecting
for i = 1:length(p_peak_loca)
    [~, P(1, i)] = max(ecg_r_peak_free(1, p_peak_loca(1, i):p_peak_loca(2, i)));
    P(1, i) = P(1, i) + p_peak_loca(1, i) - 1;
end

% Thresholding with PR interval
PR_high_threshold = 0.2 * fs;
PR_low_threshold = 0.1 * fs;
RP_low_threshold = 0.7 * fs;
% RP_low_threshold = 0.1 * fs;
p_index = 1;
r_index = 1;
% t_index = 1;
while (p_index <= length(P))
    if r_index > length(R)
        RP_temp = P(1, p_index) - R(1, r_index - 1);
        if(RP_temp < RP_low_threshold)
%             T(:, t_index) = P(:, p_index);
%             t_index = t_index + 1;
            p_boi_mark(1, p_peak_loca(1, p_index):p_peak_loca(2, p_index)) = zeros(1, p_peak_loca(2, p_index) - p_peak_loca(2, p_index) + 1);
            p_peak_loca(:, p_index) = [];
            P(:, p_index) = [];
        else
            p_index = p_index + 1;
        end
    else
        PR_temp = R(1, r_index) - P(1, p_index);
        if (PR_temp <= 0)
            r_index = r_index + 1;
        else
            if(PR_temp > PR_high_threshold) || (PR_temp < PR_low_threshold)
%                 T(:, t_index) = P(:, p_index);
%                 t_index = t_index + 1;
                p_boi_mark(1, p_peak_loca(1, p_index):p_peak_loca(2, p_index)) = zeros(1, p_peak_loca(2, p_index) - p_peak_loca(2, p_index) + 1);
                p_peak_loca(:, p_index) = [];
                P(:, p_index) = [];
            else
                p_index = p_index + 1;
            end
        end
    end
end

% Ploting P peak
if is_plotting
%     t = (0:1/fs:(length(ecg_r_peak_free) - 1)/fs);
    t = 0:(length(ecg_r_peak_free) - 1);
    figure('Name', "P and T peaks detection");
    subplot(3, 1, 1);
    plot(t, ecg_r_peak_free);
    subplot(3, 1, 2);
    hold on;
    plot(t, enhanced_ecg, 'k');
    plot(t, M_event, 'b');
    plot(t, M_cycle, 'r');
    plot(t, p_boi_mark, 'g');
    subplot(3, 1, 3);
    hold on;
    plot(t, ecg_r_peak_free);
%     plot(P/fs, ecg_r_peak_free(P), '^b', 'LineWidth', 2);
    plot(P, ecg_r_peak_free(P), '^b', 'LineWidth', 2);
end

end