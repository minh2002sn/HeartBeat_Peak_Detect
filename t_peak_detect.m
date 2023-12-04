function T = t_peak_detect(ecg_pr_peak_free, fs, is_plotting)

T = zeros(1, 1, 'double');
% Fractional Fourier Transfrorm and squaring
% enhanced_ecg = (abs(frft(ecg_pr_peak_free, 0.01))*10).^2;
% enhanced_ecg = (abs(ecg_pr_peak_free)*10).^2;
enhanced_ecg = ecg_pr_peak_free;

% Detect block of interest (BOI)
beta = 0.1;
W_event = round(0.1 * fs); % = QRS complex
if mod(W_event, 2) == 0
    W_event = W_event - 1;
end
W_cycle = 0.75 * fs; % = ECG duration
if mod(W_cycle, 2) == 0
    W_cycle = W_cycle + 1;
end
[M_event, M_cycle, t_boi_mark, t_peak_loca] = boi_gen(enhanced_ecg, W_event, W_cycle, beta);

% T peak detecting
for i = 1:length(t_peak_loca)
    [~, T(1, i)] = max(ecg_pr_peak_free(1, t_peak_loca(1, i):t_peak_loca(2, i)));
    T(1, i) = T(1, i) + t_peak_loca(1, i) - 1;
end

% Ploting T peak
if is_plotting
%     t = (0:1/fs:(length(ecg_pr_peak_free) - 1)/fs);
    t = 0:(length(ecg_pr_peak_free) - 1);
    figure('Name', "T peaks detection");
    subplot(3, 1, 1);
    plot(t, ecg_pr_peak_free);
    subplot(3, 1, 2);
    hold on;
    plot(t, enhanced_ecg, 'k');
    plot(t, M_event, 'b');
    plot(t, M_cycle, 'r');
    plot(t, t_boi_mark, 'g');
    subplot(3, 1, 3);
    hold on;
    plot(t, ecg_pr_peak_free);
%     plot(T/fs, ecg_pr_peak_free(T), 'sk', 'LineWidth', 2);
    plot(T, ecg_pr_peak_free(T), 'sk', 'LineWidth', 2);
end

end