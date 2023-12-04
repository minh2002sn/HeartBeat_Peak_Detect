function [P, R, T] = peak_detect(ecg_noise_free, fs, is_plotting_ecg, is_plotting_p, is_plotting_r, is_plotting_t)

N = length(ecg_noise_free);

% Get R peaks
disp('Detect R peaks');
R = r_peak_detect(ecg_noise_free, fs, is_plotting_r);

% Get R peak-free signal, remove 0.08s before and 0.16s after each R peak.
% ecg_r_peak_free = ecg_noise_free - min(ecg_noise_free);
% for i = R
%     if (i - 30) < 0
%         ecg_r_peak_free(1, (1):(i+60)) = zeros(1, i+60);
%     elseif (i + 60) > N
%         ecg_r_peak_free(1, (i-30):(N)) = zeros(1, N - (i - 30) + 1);
%     else
%         ecg_r_peak_free(1, (i-30):(i+60)) = zeros(1, 91);
%     end
% end

% Get P and T peaks
P = zeros(1, 1, 'uint32');
T = zeros(1, 1, 'uint32');
p_index = 1;
t_index = 1;
before_interval = 129;
after_interval = 170;
for R_peak = R
    if R_peak < 130
        P_temp = [];
        T_temp = [];
    elseif R_peak >= (length(ecg_noise_free) - after_interval)
        [P_temp, T_temp] = pt_peak_detect(ecg_noise_free(1, (R_peak - before_interval):length(ecg_noise_free)), ...
            before_interval + 1, fs, is_plotting_p, is_plotting_t);
    else
        [P_temp, T_temp] = pt_peak_detect(ecg_noise_free(1, (R_peak - before_interval):(R_peak + after_interval)), ...
            before_interval + 1, fs, is_plotting_p, is_plotting_t);
    end

    if ~isempty(P_temp)
        P(1, p_index) = R_peak - (130 - P_temp);
        p_index = p_index + 1;
    end
    if ~isempty(T_temp)
        T(1, t_index) = R_peak + (T_temp - 130);
        t_index = t_index + 1;
    end
end

% Get P peaks
% % P = 0;
% disp('Detect P peaks');
% [P] = p_peak_detect(ecg_r_peak_free, fs, R, is_plotting_p);
% 
% % Get P and R peak-free signal
% ecg_pr_peak_free = ecg_r_peak_free;
% p_index = 1;
% r_index = 1;
% num_dot_bef_p = 30;
% while (p_index <= length(P))
%     if r_index > length(R)
%         ecg_pr_peak_free(1, (P(p_index)-num_dot_bef_p):(3600)) = zeros(1, 3600 - (P(p_index) - num_dot_bef_p) + 1);
%         p_index = p_index + 1;
%     elseif (R(1, r_index) - P(1, p_index) <= 0)
%         r_index = r_index + 1;
%     else
%         if (P(p_index) - num_dot_bef_p) < 0
%             ecg_pr_peak_free(1, 1:R(r_index)) = zeros(1, R(r_index));
%         else
%             ecg_pr_peak_free(1, (P(p_index)-num_dot_bef_p):R(r_index)) = zeros(1, R(r_index) - P(p_index) + num_dot_bef_p + 1);
%         end
%         p_index = p_index + 1;
%     end
% end

% Get T peaks
% % T = 0;
% disp('Detect T peaks');
% T = t_peak_detect(ecg_pr_peak_free, fs, is_plotting_t);

% ploting P, R, T peaks
if is_plotting_ecg
    P = [1 P];
    R = [1 R];
    T = [1 T];
    t = (0:(length(ecg_noise_free) - 1));
    figure('Name', "Detected P, R, T peaks");
%     subplot(3, 1, 1);
%     plot(t, ecg_r_peak_free);
%     subplot(3, 1, 2);
%     plot(t, ecg_pr_peak_free);
%     subplot(3, 1, 3);
    hold on;
    plot(t, ecg_noise_free);
    plot(P, ecg_noise_free(P), '^b', 'LineWidth', 2);
    plot(R, ecg_noise_free(R), 'or', 'LineWidth', 2);
    plot(T, ecg_noise_free(T), 'sk', 'LineWidth', 2);
    legend('noise-free ECG signal', 'P peaks', 'R peaks', 'T peaks');
    P(:, 1) = [];
    R(:, 1) = [];
    T(:, 1) = [];
end

end
