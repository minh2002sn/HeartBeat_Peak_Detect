signal_list = 1;
N0 = 1;
N = 650000;
file_list = [100, 101, 103, 105, 106, 108, 109, ...
            111, 112, 113, 115, 116, 117, 118, 119, ...
            121, 122, 123, 124, ...
            200, 201, 202, 203, 205, 207, 208, 209, ...
            210, 212, 213, 214, 215, 219, ...
            220, 221, 222, 223, 228, ...
            230, 231, 232, 233, 234];
% Dont use: 102, 104, 107, 114, 217
% 102, 104: dont have lead II.
% 107, 217: paced rhythm.
% 114: lead II in 2nd row.
% file_list = [207];

is_plotting_ecg = false;
is_plotting_p = false;
is_plotting_r = false;
is_plotting_t = false;
is_ploting_denoised = false;
is_plotting_annotation = false;

validation = [];

for i = 1:length(file_list)
    file_name = strcat('mitdb/', num2str(file_list(i)));
    disp(file_name);
    
%     disp('Reading samples ECG signal from MIT-BIH Arrhythmia Database');
    [ecg_raw, Fs, ~] = rdsamp(file_name, signal_list, N, N0);
    ecg_raw = ecg_raw';
    
    % Normalize raw signal
    signal_max = max(ecg_raw);
    signal_min = min(ecg_raw);
    ecg_raw = 3.3*(ecg_raw - signal_min)/(signal_max - signal_min);
    
%     disp('Denoise ECG raw signal');
    ecg_noise_free = denoise_ecg(ecg_raw, Fs, is_ploting_denoised);
    
%     R = r_peak_detect_3(ecg_noise_free, Fs, is_plotting_r);
    R = r_peak_detect(ecg_noise_free, Fs, is_plotting_r);
    
    % [P, R, T] = peak_detect(ecg_noise_free, Fs, is_plotting_ecg, is_plotting_p, is_plotting_r, is_plotting_t);
    
    validation(i, :) = validate(ecg_noise_free, R, file_name, N0, N, is_plotting_annotation);
end

% validation = [];
% 
% validation(1, :) = evaluate('mitdb/100', 1, 1, 650000);
% validation(2, :) = evaluate('mitdb/101', 1, 1, 650000);
% validation(3, :) = evaluate('mitdb/103', 1, 1, 650000);
% validation(4, :) = evaluate('mitdb/105', 1, 1, 650000);
% % validation(5, :) = evaluate('mitdb/107', 1, 1, 650000);
% validation(6, :) = evaluate('mitdb/109', 1, 1, 650000);
% validation(7, :) = evaluate('mitdb/112', 1, 1, 650000);
% validation(8, :) = evaluate('mitdb/114', 2, 1, 650000);
% validation(9, :) = evaluate('mitdb/115', 1, 1, 650000);
% validation(10, :) = evaluate('mitdb/116', 1, 1, 650000);

% Dont use 102, 104, 106, 107, 108, 111, 113
% 102, 103: dont have lead II
% 107: paced rhythm
% 106, 108, 111, 113: lots of noise
