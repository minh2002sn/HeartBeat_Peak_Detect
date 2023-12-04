function validation = validate(ecg_noise_free, R, file_name, N0, N, is_plotting)

% disp('Reading and plotting annotations (human labels) of QRS complexes performend on the signals');
[ann,anntype,subtype,chan,num,comments] = rdann(file_name, 'atr', 1, N, N0);

% Preprocess annotation array
ann = ann + 1; % ann start from 0
ann = ann';
ann = ann - N0 + 1; % plus N0 ofset

R = double(R);
ann = double(ann);

% Evaluate
dif_len = abs(length(ann) - length(R));
if dif_len < 100
    dif_len = 100;
end
dif_threshold = 15; % = 0.03*360
TP = 0;
for i = 1:length(R)
    j_start = max(1, i - dif_len);
    j_stop = min(length(ann), i + dif_len);
    for j = j_start:j_stop
        if abs(R(i) - ann(j)) < dif_threshold
            TP = TP + 1;
            break;
        end
    end
end

FP = length(R) - TP;
FN = length(ann) - TP;

disp("Precision = TP/(TP + FP)");
Precision = TP/(TP + FP);
disp(Precision)

disp("Recall = TP/(TP + FN)");
Recall = TP/(TP + FN);
disp(Recall);

R_len = length(R);
ann_len = length(ann);
validation = [R_len, ann_len, TP, FN, FP, Precision, Recall];

% Plot 2D version of signal and labels
if is_plotting
    figure('Name', "Annotated peaks");
    hold on;
    grid on;
    plot(N0:N, ecg_noise_free);
    plot(ann + N0, ecg_noise_free(ann), 'go', 'LineWidth', 2);
    plot(R + N0 - 1, ecg_noise_free(R), 'ro', 'LineWidth', 2);
end

end