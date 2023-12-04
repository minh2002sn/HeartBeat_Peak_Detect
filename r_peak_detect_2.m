function R = r_peak_detect_2(ecg, fs, is_plotting_r)

% disp('Detect R peaks');

R = [];

% mirror peak
mirrored_ecg = mirror_peak(ecg, fs);

delta_ecg = zeros(1, 1, 'double');
for i = 1:(length(mirrored_ecg) - 1)
    if (mirrored_ecg(i + 1) - mirrored_ecg(i)) >= 0
        delta_ecg(i) = 1;
    else
        delta_ecg(i) = -1;
    end
end

extreme_points = zeros(1, 1, 'double');
ep_index = 1;
for i = 1:(length(delta_ecg) - 1)
    delta_ecg(i) = delta_ecg(i + 1) - delta_ecg(i);
    if delta_ecg(i) == -2
        extreme_points(ep_index) = i + 1;
        ep_index = ep_index + 1;
    end
end
first_extreme_points = extreme_points;

% find max amplitude
time_frame = 5; % in second
k_amp = 0.5; % from 0.2 to 0.3
k_time = 0.42; % from 0.42 to 0.43
max_amp = max(ecg(extreme_points(extreme_points < time_frame*fs)));
avr_rr_int = 0.8*fs;
% disp('max_amp = ');
% disp(max_amp);
% disp('avr_peaks_interval = ');
% disp(avr_rr_int);
% disp('k_amp*max_amp = ');
% disp(k_amp*max_amp)

% extreme_points = extreme_points(mirrored_ecg(extreme_points) >= k_amp*max_amp);

R = [];
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
%                 R = [R extreme_points(T_ref)];
%                 ep_index = ep_index + 1;
                extreme_points(C_ref) = [];
            elseif W_T_ref > W_C_ref
                extreme_points(T_ref) = [];
            else % W_T_ref == W_C_ref
                if mirrored_ecg(extreme_points(T_ref)) >= mirrored_ecg(extreme_points(C_ref))
%                     R = [R extreme_points(T_ref)];
%                     ep_index = ep_index + 1;
                    extreme_points(C_ref) = [];
                else
                    extreme_points(T_ref) = [];
                end
            end
        end
    end
end

% while ep_index <= length(extreme_points)
% % for i = 1:length(extreme_points)
%     if extreme_points > time_frame*fs
%         [max_amp, avr_rr_int] = find_threshold(mirrored_ecg, R, ...
%             extreme_points(ep_index), extreme_points(ep_index) - time_frame*fs);
%     end
% %         disp('max_amp = ');
% %         disp(max_amp);
% %         disp('avr_peaks_interval');
% %         disp(avr_int);
%     
%     if(mirrored_ecg(extreme_points(ep_index)) < k_amp*max_amp)
%         extreme_points(ep_index) = [];
%         continue;
%     else
%         ref_data = [ref_data ep_index];
%     end
% 
%     if length(ref_data) <= 1
%         ep_index = ep_index + 1;
%         continue;
%     else
%         if (extreme_points(ref_data(2)) - extreme_points(ref_data(1))) > k_time*avr_rr_int
%             ref_data(1) = [];
%             ep_index = ep_index + 1;
%         else
%             w1 = find_width(mirrored_ecg, extreme_points(ref_data(1)));
%             w2 = find_width(mirrored_ecg, extreme_points(ref_data(2)));
%             if w1 < w2
%                 R = [R extreme_points(ref_data(1))];
%                 ref_data(1) = [];
%             elseif w1 == w2
%                 if mirrored_ecg(ref_data(1)) > mirrored_ecg(ref_data(2))
%                     R = [R extreme_points(ref_data(1))];
%                     ref_data(1) = [];
%                 else
%                     ref_data(2) = [];
%                     extreme_points(ep_index) = [];
%                 end
%             else
%                 ref_data(1) = [];
%                 extreme_points(ep_index - 1) = [];
%             end
%         end
%     end
% end

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
    hold on;
    grid on;
    plot(t, mirrored_ecg, 'b');
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