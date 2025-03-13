function VEL_Plot_ENU(navSolutionsCT, fileType, filename)
% Function to plot velocity components in ENU (East-North-Up) coordinates
% Inputs:
% navSolutionsCT - Structure containing estimated ENU velocities
% fileType - String indicating the type of data ('Urban' or 'Open Sky')
% filename - String containing the filename (optional, for method detection)

figure;
hold on;
time = navSolutionsCT.localTime;
VelEast = navSolutionsCT.usrVelENU(:,1); % Estimated velocity in the East direction
VelNorth = navSolutionsCT.usrVelENU(:,2); % Estimated velocity in the North direction
VelUp = navSolutionsCT.usrVelENU(:,3); % Estimated velocity in the Up direction

% Plot velocity components over time
plot(time, VelEast, 'b-'); % Velocity in East direction
plot(time, VelNorth, 'r-'); % Velocity in North direction
plot(time, VelUp, 'g-'); % Velocity in Up direction
hold off;

% Set axis labels
xlabel('Local Time (ms)');
ylabel('Velocity (m/s)');

% Show legend
legend('Velocity E', 'Velocity N', 'Velocity U');

% Determine solution method based on filename
if nargin < 3
    % Default method is OLS if not specified
    methodType = 'OLS';
else
    % Check if filename contains method indicators
    if contains(filename, '_WLS_')
        methodType = 'WLS';
    elseif contains(filename, '_KF_')
        methodType = 'KF';
    else
        methodType = 'OLS';
    end
end

% Set figure title based on file type and method
title(['Velocity Components Over Time - ' fileType ' Environment (' methodType ')']);

% Enable grid
grid on;
end

% Example usage with automatic method detection:
filename = 'navSolCT_1ms_Urban.mat';
load(filename);
urban = navSolutionsCT;
VEL_Plot_ENU(navSolutionsCT, 'Urban', filename);

filename = 'navSolCT_1ms_Opensky.mat';
load(filename);
openSky = navSolutionsCT;
VEL_Plot_ENU(navSolutionsCT, 'Open Sky', filename);

filename = 'navSolCT_KF_1ms_Opensky.mat';
load(filename);
openSkyKF = navSolutionsCT_KF;
VEL_Plot_ENU(navSolutionsCT_KF, 'Open Sky', filename);

filename = 'navSolCT_KF_1ms_Urban.mat';
load(filename);
urbanKF = navSolutionsCT_KF;
VEL_Plot_ENU(navSolutionsCT_KF, 'Urban', filename);

filename = 'navSolCT_WLS_1ms_Urban.mat';
load(filename);
urbanWLS = navSolutionsCT_WLS;
VEL_Plot_ENU(navSolutionsCT_WLS, 'Urban', filename);

filename = 'navSolCT_WLS_1ms_Opensky.mat';
load(filename);
openSkyWLS = navSolutionsCT_WLS;
VEL_Plot_ENU(navSolutionsCT_WLS, 'Open Sky', filename);


urban.usrPosLLH = urban.usrPosLLH(1:3389,:);
urban.localTime = urban.localTime(1:3389,:);
urbanGT = [22.3198722, 114.209101777778];
urbanGTECEF = llh2xyz([urbanGT(1)/180 * pi,urbanGT(2)/180 * pi, 7]);
urbanLocalTime = urban.localTime(:);

for i = 1:length(urban.localTime)
    urban.usrPosRMSE(i) = norm(urban.usrPos(i,1:2) - urbanGTECEF(1:2));
end
urban.usrPosRMSEMean = mean(urban.usrPosRMSE);
urban.usrPosRMSESTD = std(urban.usrPosRMSE);

openSkyGT = [22.328444770087565, 114.1713630049711];
openSkyGTECEF = llh2xyz([openSkyGT(1)/180 * pi,openSkyGT(2)/180 * pi, 3]);
openSkyLocalTime = openSky.localTime(:);

for i = 1:length(openSky.localTime)
    openSky.usrPosRMSE(i) = norm(openSky.usrPos(i,1:2) - openSkyGTECEF(1:2));
end

openSky.usrPosRMSEMean = mean(openSky.usrPosRMSE);
openSky.usrPosRMSESTD = std(openSky.usrPosRMSE);

urbanWLSLocalTime = urbanWLS.localTime(:);

for i = 1:length(urbanWLS.localTime)
    urbanWLS.usrPosRMSE(i) = norm(urbanWLS.usrPos(i,1:2) - urbanGTECEF(1:2));
end
urbanWLS.usrPosRMSEMean = mean(urbanWLS.usrPosRMSE);
urbanWLS.usrPosRMSESTD = std(urbanWLS.usrPosRMSE);

openSkyWLSLocalTime = openSkyWLS.localTime(:);

for i = 1:length(openSkyWLS.localTime)
    openSkyWLS.usrPosRMSE(i) = norm(openSkyWLS.usrPos(i,1:2) - openSkyGTECEF(1:2));
end
openSkyWLS.usrPosRMSEMean = mean(openSkyWLS.usrPosRMSE);
openSkyWLS.usrPosRMSESTD = std(openSkyWLS.usrPosRMSE);

urbanKFLocalTime = urbanKF.localTime(:);

for i = 1:length(urbanKF.localTime)
    urbanKF.usrPosRMSE(i) = norm(urbanKF.usrPos(i,1:2) - urbanGTECEF(1:2));
end
urbanKF.usrPosRMSEMean = mean(urbanKF.usrPosRMSE);
urbanKF.usrPosRMSESTD = std(urbanKF.usrPosRMSE);

openSkyKFLocalTime = openSkyKF.localTime(:);

for i = 1:length(openSky.localTime)
    openSkyKF.usrPosRMSE(i) = norm(openSkyKF.usrPos(i,1:2) - openSkyGTECEF(1:2));
end
openSkyKF.usrPosRMSEMean = mean(openSkyKF.usrPosRMSE);
openSkyKF.usrPosRMSESTD = std(openSkyKF.usrPosRMSE);


%% Urban
% Pos ECEF RMSE
figure
plot(urbanLocalTime,urban.usrPosRMSE)
hold on
plot(urbanWLSLocalTime,urbanWLS.usrPosRMSE)
hold on
plot(urbanKFLocalTime,urbanKF.usrPosRMSE)
hold off
title('Urban Positioning RMSE')
legend('OLS','WLS','EKF')
xlabel('Epoch (s)')
ylabel('RMSE (m)')
xlim([urbanWLSLocalTime(1) urbanWLSLocalTime(end)])
grid on

%% Open Sky
% Pos ECEF RMSE
figure
plot(openSkyLocalTime,openSky.usrPosRMSE)
hold on
plot(openSkyWLSLocalTime,openSkyWLS.usrPosRMSE)
hold on
plot(openSkyKFLocalTime,openSkyKF.usrPosRMSE)
hold off
title('Open Sky Positioning RMSE')
legend('OLS','WLS','EKF')
xlabel('Epoch (s)')
ylabel('RMSE (m)')
xlim([openSkyWLSLocalTime(1) openSkyWLSLocalTime(end)])
grid on