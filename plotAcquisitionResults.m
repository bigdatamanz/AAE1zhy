function plotAcquisitionResults(Acquired, fileName)
% plotAcquisitionResults - Plot satellite signal acquisition results
%
% Inputs:
%   Acquired - Acquisition results structure, containing sv (PRN) and SNR
%   fileName - Data file name, used for figure title

% Initialize acquisition metrics array using SNR values for all satellites
if isfield(Acquired, 'allSNR')
    % If allSNR field exists, use actual SNR values for all satellites
    acquisitionMetric = Acquired.allSNR ; 
else
    % For backward compatibility with older data
    acquisitionMetric = ones(1, 32) * 1.2;
    % Mark acquired satellites
    for i = 1:length(Acquired.sv)
        prn = Acquired.sv(i);
        acquisitionMetric(prn) = Acquired.SNR(i) ;
    end
end

% Create color array
colors = repmat([0 0.4470 0.7410], 32, 1); % Default blue for non-acquired
for i = 1:length(Acquired.sv)
    prn = Acquired.sv(i);
    colors(prn,:) = [0.4660 0.6740 0.1880]; % Green for acquired
end

% Create figure
figure;
h = bar(1:32, acquisitionMetric, 'FaceColor', 'flat');

% Apply colors
for i = 1:32
    h.CData(i,:) = colors(i,:);
end

% Set figure properties
xlabel('PRN Number (No bar - satellite not in acquisition list)');
ylabel('Acquisition Metric (SNR in dB)');
title(['Acquisition Results - ', fileName]);
xlim([0 33]);
ylim([0 max(acquisitionMetric)*1.1]); % Dynamically set Y-axis range
grid on;

% Add legend
hold on;
legend_handles = [
    bar(NaN, NaN, 'FaceColor', [0 0.4470 0.7410]), 
    bar(NaN, NaN, 'FaceColor', [0.4660 0.6740 0.1880])
];
legend(legend_handles, {'Non-acquired Signal', 'Acquired Signal'});
hold off;

end