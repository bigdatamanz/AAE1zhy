function GNSS_Results_Visualization()
% GNSS_Results_Visualization - Generate visualization plots for GNSS positioning results
%
% This script generates a series of visualization plots for GNSS positioning results
% in both Urban and Open Sky environments, using different positioning methods:
% OLS (Ordinary Least Squares), WLS (Weighted Least Squares), and KF (Kalman Filter).
%
% Usage:
% GNSS_Results_Visualization()

    % Ground truth coordinates
    OpenskyGT = [22.328444770087565, 114.1713630049711];
    UrbanGT = [22.3198722, 114.209101777778];
    
    % Create Figures directory if it doesn't exist
    if ~exist('Figures', 'dir')
        mkdir('Figures');
    end
    
    % Data collection structures for combined plots
    urbanData = struct();
    openSkyData = struct();
    
    % Process each method and collect data
    methods = {'OLS', 'WLS', 'KF'};
    for i = 1:length(methods)
        method = methods{i};
        [urbanResult, openSkyResult] = plotMethodResults(method, OpenskyGT, UrbanGT);
        
        % Store results for combined plots
        urbanData.(method) = urbanResult;
        openSkyData.(method) = openSkyResult;
    end
    
    % Create combined comparison plots
    createComparisonPlot(urbanData, UrbanGT, 'Urban');
    createComparisonPlot(openSkyData, OpenskyGT, 'Open Sky');
    
    % Create combined comparison plots in ENU coordinates
    createComparisonPlotENU(urbanData, 'Urban');
    createComparisonPlotENU(openSkyData, 'Open Sky');
end

function [urbanResult, openSkyResult] = plotMethodResults(method, OpenskyGT, UrbanGT)
    % Function to plot positioning results for a specific method
    % Inputs:
    %   method - String indicating the method ('OLS', 'WLS', 'KF')
    %   OpenskyGT - Ground truth coordinates for Open Sky environment
    %   UrbanGT - Ground truth coordinates for Urban environment
    % Outputs:
    %   urbanResult - Structure with Urban environment positioning results
    %   openSkyResult - Structure with Open Sky environment positioning results
    
    % File suffix based on method
    fileSuffix = '';
    if ~strcmp(method, 'OLS')
        fileSuffix = ['_' method];
    end
    
    % Load data
    openskyFile = ['navSolCT' fileSuffix '_1ms_Opensky.mat'];
    urbanFile = ['navSolCT' fileSuffix '_1ms_Urban.mat'];
    
    % Load Open Sky data
    load(openskyFile);
    
    % Get the correct variable based on method
    if strcmp(method, 'OLS')
        OpenskySolutionCT = navSolutionsCT;
    elseif strcmp(method, 'WLS')
        OpenskySolutionCT = navSolutionsCT_WLS;
    elseif strcmp(method, 'KF')
        OpenskySolutionCT = navSolutionsCT_KF;
    end
    
    % Store result for later comparison plots
    openSkyResult = OpenskySolutionCT;
    
    % Load Urban data
    load(urbanFile);
    
    % Get the correct variable based on method
    if strcmp(method, 'OLS')
        UrbanSolutionCT = navSolutionsCT;
    elseif strcmp(method, 'WLS')
        UrbanSolutionCT = navSolutionsCT_WLS;
    elseif strcmp(method, 'KF')
        UrbanSolutionCT = navSolutionsCT_KF;
    end
    
    % Store result for later comparison plots
    urbanResult = UrbanSolutionCT;
    
    % Plot Latitude - Open Sky
    plotCoordinate(OpenskySolutionCT, 1, 'Open Sky', 'Latitude', method, "#0072BD");
    
    % Plot Latitude - Urban
    plotCoordinate(UrbanSolutionCT, 1, 'Urban', 'Latitude', method, "#D95319");
    
    % Plot Longitude - Open Sky
    plotCoordinate(OpenskySolutionCT, 2, 'Open Sky', 'Longitude', method, "#0072BD");
    
    % Plot Longitude - Urban
    plotCoordinate(UrbanSolutionCT, 2, 'Urban', 'Longitude', method, "#D95319");
    
    % Plot individual method map
    plotMap(OpenskySolutionCT, UrbanSolutionCT, OpenskyGT, UrbanGT, method);
end

function plotCoordinate(solutionCT, coordIndex, environment, coordType, method, colorCode)
    % Function to plot a specific coordinate (latitude or longitude)
    % Inputs:
    %   solutionCT - Structure containing positioning results
    %   coordIndex - Index of coordinate to plot (1 for latitude, 2 for longitude)
    %   environment - String indicating environment ('Urban' or 'Open Sky')
    %   coordType - String indicating coordinate type ('Latitude' or 'Longitude')
    %   method - String indicating method ('OLS', 'WLS', 'KF')
    %   colorCode - String with color code for plot
    
    % Limit to 3000 points for OLS for consistency with original code
    if strcmp(method, 'OLS')
        timeData = solutionCT.localTime(1:3000);
        coordData = solutionCT.usrPosLLH(1:3000, coordIndex);
        enuData = solutionCT.usrPosENU(1:3000, coordIndex);
        
    else
        timeData = solutionCT.localTime;
        coordData = solutionCT.usrPosLLH(:, coordIndex);
        enuData = solutionCT.usrPosENU(:, coordIndex);
        
    end
    
    % Create figure for LLH coordinates
    figure;
    plot(timeData, coordData, 'Color', colorCode, 'LineWidth', 1);
    xlabel('Time (ms)');
    ylabel('^\circ');
    title([environment ' ' lower(coordType) ' - ' method ' method']);
    grid on;
    
    % Set figure properties
    set(gcf, 'Units', 'inches');
    set(gcf, 'Position', [0, 0, 3.25, 3.25*3/4]);
    set(gca, 'FontSize', 8, 'FontName', 'Times New Roman');
    
    % Generate file suffix based on method
    methodSuffix = '';
    if ~strcmp(method, 'OLS')
        methodSuffix = ['_' method];
    end
    
    % Save figure
    print(['Figures/' environment ' ' lower(coordType) methodSuffix], '-dpng', '-r600');
end

function plotMap(OpenskySolutionCT, UrbanSolutionCT, OpenskyGT, UrbanGT, method)
    % Function to plot geographic scatter plot for a single method
    % Inputs:
    %   OpenskySolutionCT - Structure containing Open Sky positioning results
    %   UrbanSolutionCT - Structure containing Urban positioning results
    %   OpenskyGT - Ground truth coordinates for Open Sky environment
    %   UrbanGT - Ground truth coordinates for Urban environment
    %   method - String indicating method ('OLS', 'WLS', 'KF')
    
    % Limit to 3000 points for OLS for consistency with original code
    if strcmp(method, 'OLS')
        openSkyLat = OpenskySolutionCT.usrPosLLH(1:3000, 1);
        openSkyLon = OpenskySolutionCT.usrPosLLH(1:3000, 2);
        urbanLat = UrbanSolutionCT.usrPosLLH(1:3000, 1);
        urbanLon = UrbanSolutionCT.usrPosLLH(1:3000, 2);
    else
        openSkyLat = OpenskySolutionCT.usrPosLLH(:, 1);
        openSkyLon = OpenskySolutionCT.usrPosLLH(:, 2);
        urbanLat = UrbanSolutionCT.usrPosLLH(:, 1);
        urbanLon = UrbanSolutionCT.usrPosLLH(:, 2);
    end
    
    % Create figure
    figure;
    
    % Add satellite map as background
    geobasemap('topographic');
    
    % Plot data
    geoscatter(urbanLat, urbanLon, 1, 'g', 'filled');
    hold on;
    geoscatter(UrbanGT(1), UrbanGT(2), 5, 'r', 'filled');
    geoscatter(openSkyLat, openSkyLon, 1, 'c', 'filled');
    geoscatter(OpenskyGT(1), OpenskyGT(2), 5, 'b', 'filled');
    title(['Positioning Results - ' method ' method']);
    legend('Urban', 'Urban GT', 'Open Sky', 'Open Sky GT', 'Location', 'northwest');
    
    % Set figure properties
    set(gcf, 'Units', 'inches');
    set(gcf, 'Position', [0, 0, 3.25, 3.25*3/4]);
    set(gca, 'FontSize', 8, 'FontName', 'Times New Roman');
    
    % Generate file suffix based on method
    methodSuffix = '';
    if ~strcmp(method, 'OLS')
        methodSuffix = ['_' method];
    end
    
    % Save figure
    print(['Figures/Map' methodSuffix], '-dpng', '-r600');
end

function createComparisonPlot(environmentData, GT, environmentName)
    % Function to create a comparison plot for a specific environment with all methods
    % Inputs:
    %   environmentData - Structure containing positioning results for all methods
    %   GT - Ground truth coordinates for the environment
    %   environmentName - String name of the environment ('Urban' or 'Open Sky')
    
    % Create figure
    figure;
    
    % Add satellite map as background
    geobasemap('topographic');
    
    % Define colors and markers for different methods
    colors = {'g', 'c', 'm'};
    
    % Plot data for each method
    methods = {'OLS', 'WLS', 'KF'};
    legendEntries = {};
    
    for i = 1:length(methods)
        method = methods{i};
        color = colors{i};
        
        % Get data
        if strcmp(method, 'OLS')
            % Limit to 3000 points for OLS
            lat = environmentData.(method).usrPosLLH(1:3000, 1);
            lon = environmentData.(method).usrPosLLH(1:3000, 2);
        else
            lat = environmentData.(method).usrPosLLH(:, 1);
            lon = environmentData.(method).usrPosLLH(:, 2);
        end
        
        % Plot
        geoscatter(lat, lon, 1, color, 'filled');
        hold on;
        
        % Add to legend entries
        legendEntries{end+1} = [environmentName ' ' method];
    end
    
    % Add ground truth
    geoscatter(GT(1), GT(2), 10, 'r', 'filled', 'MarkerEdgeColor', 'k');
    legendEntries{end+1} = [environmentName ' GT'];
    
    % Add title and legend
    title([environmentName ' Positioning Results - Method Comparison']);
    legend(legendEntries, 'Location', 'northwest');
    
    % Set figure properties
    set(gcf, 'Units', 'inches');
    set(gcf, 'Position', [0, 0, 5, 5*3/4]);
    set(gca, 'FontSize', 8, 'FontName', 'Times New Roman');
    
    % Save figure
    print(['Figures/' environmentName '_Method_Comparison'], '-dpng', '-r600');
end

function createComparisonPlotENU(environmentData, environmentName)
    % Function to create a comparison plot for a specific environment with all methods in ENU coordinates
    % Inputs:
    %   environmentData - Structure containing positioning results for all methods
    %   environmentName - String name of the environment ('Urban' or 'Open Sky')
    
    % Create figure
    figure;
    
    % Define colors and markers for different methods
    colors = {'g', 'c', 'm'};
    
    % Plot data for each method
    methods = {'OLS', 'WLS', 'KF'};
    legendEntries = {};
    
    for i = 1:length(methods)
        method = methods{i};
        color = colors{i};
        
        % Get data
        if strcmp(method, 'OLS')
            % Limit to 3000 points for OLS
            east = environmentData.(method).usrPosENU(1:3000, 1);
            north = environmentData.(method).usrPosENU(1:3000, 2);
        else
            east = environmentData.(method).usrPosENU(:, 1);
            north = environmentData.(method).usrPosENU(:, 2);
        end
        
        % Plot
        scatter(east, north, 1, color, 'filled');
        hold on;
        
        % Add to legend entries
        legendEntries{end+1} = [environmentName ' ' method];
    end
    
    % Add origin (ground truth)
    scatter(0, 0, 10, 'r', 'filled', 'MarkerEdgeColor', 'k');
    legendEntries{end+1} = [environmentName ' GT'];
    
    % Add title and legend
    title([environmentName ' Positioning Results (ENU) - Method Comparison']);
    legend(legendEntries, 'Location', 'northwest');
    xlabel('East (m)');
    ylabel('North (m)');
    grid on;
    
    % Set figure properties
    set(gcf, 'Units', 'inches');
    set(gcf, 'Position', [0, 0, 5, 5*3/4]);
    set(gca, 'FontSize', 8, 'FontName', 'Times New Roman');
    
    % Save figure
    print(['Figures/' environmentName '_Method_Comparison_ENU'], '-dpng', '-r600');
end
