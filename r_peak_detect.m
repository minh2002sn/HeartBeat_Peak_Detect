function R = r_peak_detect(ecg_noise_free, fs, is_plotting)
% Fractional Fourier Transfrorm and squaring
% enhanced_ecg = abs(frft(ecg_noise_free, 0.01)).^2;
enhanced_ecg = ecg_noise_free.^2;
% enhanced_ecg = mirror_peak(ecg_noise_free, fs);

% Detect block of interest (BOI)
beta = 0.2;
W_event = round(0.1 * fs); % = QRS complex
if mod(W_event, 2) == 0
    W_event = W_event - 1;
end
W_cycle = 0.75 * fs; % = ECG duration
if mod(W_cycle, 2) == 0
    W_cycle = W_cycle + 1;
end
[M_event, M_cycle, r_boi_mark, r_peak_loca] = boi_gen(enhanced_ecg, W_event, W_cycle, beta, true);

% R peak detecting
R = zeros(1, 1, 'int32');
for i = 1:length(r_peak_loca)
    [~, R(1, i)] = max(ecg_noise_free(1, r_peak_loca(1, i):r_peak_loca(2, i)));
    R(1, i) = R(1, i) + r_peak_loca(1, i) - 1;
end

% Filtering with RR interval
RR_threshold = 0.75 * (fs * 0.75); % 0.75 of ECG duration
i = 2;
while i <= length(R)
    if (R(1, i) - R(1, i - 1)) < RR_threshold
        R(:, i) = [];
    else
        i = i + 1;
    end
end

% Ploting R peak
if is_plotting
    t = (0:(length(ecg_noise_free) - 1));
%     t = (0:1/fs:(length(ecg_noise_free) - 1)/fs);
    figure('Name', "R peaks detection");
    subplot(3, 1, 1);
    plot(t, ecg_noise_free);
    subplot(3, 1, 2);
    ylim([-0.5 1.5]);
    hold on;
    plot(t, enhanced_ecg, 'k');
    plot(t, M_event, 'b');
    plot(t, M_cycle, 'r');
    plot(t, r_boi_mark, 'g');
    legend('Enhanced ECG', 'M_event', 'M_cycle', 'R peaks''s block of interest');
    subplot(3, 1, 3);
    hold on;
    grid on
    plot(t, ecg_noise_free);
    plot(R, ecg_noise_free(R), 'or', 'LineWidth', 2);
%     plot(R/fs, ecg_noise_free(R), 'o');
end

end

function [mirrored_peak] = mirror_peak(ecg, fs)
mirrored_peak = ecg;
N = length(ecg);
range = round(0.278*fs/10);
multiple_time = 1.5;
for i = 1:N
    % Reject positive point
    if ecg(i) >= 0
        continue;
    end
    % check 0.0278s before
    is_ptn_before = false;
    for j = max([1, (i - 1)]):-1:max([1, i - range])
        if (ecg(j) < 0) && (abs(ecg(i)) >= abs(multiple_time*ecg(j)))
            is_ptn_before = true;
            break;
        end
    end
    % check 0.0278s after
    is_ptn_after = false;
    for j = min([N, i + 1]):min([N, (i + range)])
        if (ecg(j) < 0) && (abs(ecg(i)) >= abs(multiple_time*ecg(j)))
            is_ptn_after = true;
            break;
        end
    end
    % mirror valid negative point
    if is_ptn_before && is_ptn_after
        mirrored_peak(i) = -mirrored_peak(i);
    end
end
end