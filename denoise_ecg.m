function ecg_denoise = denoise_ecg(ecg_raw, fs, is_plotting)
% mat_name = strcat('data\', name, '.mat');
% load(mat_name);
% ecg_raw = val(1, :) / gain;

% Removing baseline drift
[c, l] = wavedec(ecg_raw, 8, "db4");
nc = wthcoef("d", c, l, [1 2 3 4 5 6 7 8], [100 100 100 100 100 100 100 50]);
baseline_drift = waverec(nc, l, "db4");
ecg_rm_bd = ecg_raw - baseline_drift;

% Removing high frequency noise
% [c, l] = wavedec(ecg_rm_bd, 4, "db4");
% nc = wthcoef("d", c, l, [1 2 3 4]);
[c, l] = wavedec(ecg_rm_bd, 4, "db4");
nc = wthcoef("d", c, l, [1 2 3 4], [100 100 90 90]);
ecg_denoise = waverec(nc, l, "db4");

if is_plotting
    t = (0:(length(ecg_raw) - 1));
%     t = (0:1/fs:(length(ecg_raw) - 1)/fs);
    figure('Name', "ECG denoise");
    subplot(3, 1, 1);
    hold on;
    grid on;
    plot(t, ecg_raw);
    plot(t, baseline_drift, 'r');
    legend('Raw ECG signal', 'Baseline drift');
    ylabel('(mV)');
    xlabel('Time (sec)');
    title('Raw ECG signal and baseline drift.');
    subplot(3, 1, 2);
    hold on;
    grid on;
    plot(t, ecg_rm_bd);
    ylabel('(mV)');
    xlabel('Time (sec)');
    title('Baseline drift-free ECG signal.');
    subplot(3, 1, 3);
    hold on;
    grid on;
    plot(t, ecg_denoise);
    ylabel('(mV)');
    xlabel('Time (sec)');
    title('Noise-free ECG.');
end