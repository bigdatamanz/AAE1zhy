function AcquisitionPlot(acq, svindex, Acquired, signal)
% AcquisitionPlot - Create 3D visualization of acquisition results
%
% Inputs:
%   acq - Acquisition parameters structure
%   svindex - Satellite PRN number to plot
%   Acquired - Acquisition results structure
%   signal - Signal parameters structure

% Create 3D acquisition visualization
figure(svindex);
hold on;

% Calculate maximum frequency
freqMax = acq.freqMin + (acq.freqNum - 1) * acq.freqStep;

% Create grid where Y-axis represents Doppler frequency (freqMin to freqMax)
% and X-axis represents code phase (samples)
[X, Y] = meshgrid(1:signal.Sample, acq.freqMin:acq.freqStep:freqMax);
correlation = Acquired.correlation{svindex};
surf(X, Y, correlation, 'EdgeColor', 'none'); % Plot 3D surface

% Set axis labels
xlabel('Code Phase (samples)', 'FontSize', 12);
ylabel('Doppler Frequency (Hz)', 'FontSize', 12);
zlabel('Correlation Power', 'FontSize', 12);
title(sprintf('GPS Signal Acquisition - PRN %d', svindex), 'FontSize', 14);

% Color mapping and optimization
colormap(jet);    % Use jet colormap
colorbar;         % Show color bar
shading interp;   % Smooth shading
view([-40, 30]);  % Set 3D view angle

% Find maximum peak in correlation matrix and its corresponding X, Y, Z coordinates
[max_corr, idx] = max(correlation(:)); % Find maximum correlation value
[row, col] = ind2sub(size(correlation), idx); % Find corresponding row and column

% Calculate corresponding X, Y, Z values
peak_X = X(row, col);   % Code phase (samples)
peak_Y = Y(row, col);   % Doppler frequency (Hz)
peak_Z = max_corr;      % Correlation power

% Mark the peak with a red dot
plot3(peak_X, peak_Y, peak_Z, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

% Add text label with peak information
text(peak_X, peak_Y, peak_Z*1.1, sprintf('Peak: %.1f\nDoppler: %.1f Hz\nCode Phase: %d', ...
    peak_Z, peak_Y, peak_X), 'FontSize', 10);

hold off;
end