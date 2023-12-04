function R = r_peak_detect_3(ecg, fs, is_plotting_r)

% disp('Detect R peaks');

R = [];

% mirror peak
mirrored_ecg = mirror_peak(ecg, fs);

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
[M_event, M_cycle, r_boi_mark, r_peak_loca] = boi_gen(mirrored_ecg, W_event, W_cycle, beta, false);

% Extreme point detecting
extreme_points = zeros(1, 1, 'uint32');
for i = 1:length(r_peak_loca)
    [~, extreme_points(1, i)] = max(mirrored_ecg(1, r_peak_loca(1, i):r_peak_loca(2, i)));
    extreme_points(1, i) = extreme_points(1, i) + r_peak_loca(1, i) - 1;
end
first_extreme_points = extreme_points;

% find max amplitude
time_frame = 5; % in second
k_amp = 0.45; % from 0.2 to 0.3
k_time = 0.42; % from 0.42 to 0.43
max_amp = max(ecg(extreme_points(extreme_points < time_frame*fs)));
avr_rr_int = 0.8*fs;

ep_index = 1;
while ep_index <= length(extreme_points)
    if extreme_points > time_frame*fs
        [max_amp, avr_rr_int] = find_threshold(mirrored_ecg, R, ...
            extreme_points(ep_index), extreme_points(ep_index) - time_frame*fs);
    end
    if(mirrored_ecg(extreme_points(ep_index)) < k_amp*max_amp)
        extreme_points(ep_index) = [];
        continue;
    end
    if ep_index <= 1
        ep_index = ep_index + 1;
        continue;
    else
        T_ref = ep_index - 1; % True point reference
        C_ref = ep_index; % Comparision point reference
        delta_time = extreme_points(C_ref) - extreme_points(T_ref);
        if delta_time >= k_time*avr_rr_int
            R = [R extreme_points(T_ref)];
            ep_index = ep_index + 1;
        else
            W_T_ref = find_width(mirrored_ecg, extreme_points(T_ref));
            W_C_ref = find_width(mirrored_ecg, extreme_points(C_ref));
            if W_T_ref < W_C_ref
                extreme_points(C_ref) = [];
            elseif W_T_ref > W_C_ref
                extreme_points(T_ref) = [];
            else % W_T_ref == W_C_ref
                if mirrored_ecg(extreme_points(T_ref)) >= mirrored_ecg(extreme_points(C_ref))
                    extreme_points(C_ref) = [];
                else
                    extreme_points(T_ref) = [];
                end
            end
        end
    end
end

% Ploting R peak
if is_plotting_r
    t = (0:(length(ecg) - 1));
    figure('Name', "R peaks detection");
    subplot(3, 1, 1);
    hold on;
    grid on;
    plot(t, mirrored_ecg, 'b');
    plot(t, ecg, 'r');
    subplot(3, 1, 2);
    ylim([-2 3.3]);
    hold on;
    grid on;
    plot(t, mirrored_ecg, 'k');
    plot(t, M_event, 'b');
    plot(t, M_cycle, 'r');
    plot(t, r_boi_mark, 'g');
    plot(first_extreme_points, mirrored_ecg(first_extreme_points), 'or');
    subplot(3, 1, 3);
    hold on;
    grid on;
    plot(t, mirrored_ecg, 'b');
    plot(R, mirrored_ecg(R), 'or');
%     subplot(3, 1, 3);
%     hold on;
%     grid on
%     plot(t, ecg_noise_free);
%     plot(R, ecg_noise_free(R), 'or', 'LineWidth', 2);
% %     plot(R/fs, ecg_noise_free(R), 'o');
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


function [max_amp, avr_peaks_interval] = find_threshold(signal, R, N, N0)
if length(R) < 2
    return;
end
max_amp = -3.3;
avr_peaks_interval = 0;
for i = 1:(length(R))
    if (R(i) > N)
        break;
    end
    if (R(i) >= N0)
        if (i < length(R)) && (R(i + 1) <= N)
            avr_peaks_interval = avr_peaks_interval + R(i + 1) - R(i);
        end
        if signal(R(i)) > max_amp
            max_amp = signal(R(i));
        end
    end
end
avr_peaks_interval = avr_peaks_interval/(length(R) - 1);
if avr_peaks_interval < 0.5
    avr_peaks_interval = 0.5;
end
end


function [width] = find_width(signal, peak)
width = 1;
i = 1;
while (peak - i) > 0
    if signal(peak - i) <= 0
        break;
    end
    i = i + 1;
    width = width + 1;
end
i = 1;
while (peak + i) <= length(signal)
    if signal(peak + i) <= 0
        break;
    end
    i = i + 1;
    width = width + 1;
end
end