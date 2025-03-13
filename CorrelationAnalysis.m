load('tckRstCT_5ms_Urban.mat')
load('Acquired_Urban_0.mat')
urbanTck = TckResultCT_pos;
urbanCN0 = CN0_CT;
urbanSV = Acquired.sv;

load('tckRstCT_5ms_Opensky.mat')
load('Acquired_Opensky_0.mat')
openSkyTck = TckResultCT_pos;
openSkyCN0 = CN0_CT;
openSkySV = Acquired.sv;

Spacing = 0.6:-0.05:-0.6;
plotSamplingInterv = 1000;

%% Urban ACF Construction
h = waitbar(0,['Constructing Urban ACF ...']);
for i = 1:length(urbanTck(urbanSV(1)).E)
    waitbar(i/length(urbanTck(urbanSV(1)).E),h)
    for svInd = 1:length(urbanSV)
        prn = urbanSV(svInd);
        urbanTck(prn).ACF(i,:) = [urbanTck(prn).E(i) urbanTck(prn).E2(i) urbanTck(prn).E3(i) ...
            urbanTck(prn).E4(i) urbanTck(prn).E5(i) urbanTck(prn).P(i) ...
            urbanTck(prn).L2(i) urbanTck(prn).L3(i) urbanTck(prn).L4(i) ...
            urbanTck(prn).L5(i) urbanTck(prn).L(i)];
    end
end
close(h)

%% Urban ACF Plot
h = waitbar(0,['Plotting Urban ACF ...']);
figure
for i = 1:plotSamplingInterv:length(urbanTck(urbanSV(1)).E)
    waitbar(i/length(urbanTck(urbanSV(1)).E),h)
    for svInd = 1:length(urbanSV)
        prn = urbanSV(svInd);
        plot(Spacing(3:2:23),urbanTck(prn).ACF(i,:))
        hold on
    end
end
hold off
grid on
title('Urban Correlation Plot')
xlabel('Time Delay (Chip)')
ylabel('Correlation Value')
close(h)

%% Urban C/N0 Plot
figure
legendEntries = {};
for i = 1:plotSamplingInterv/10:length(urbanCN0)
    for svInd = 1:length(urbanSV)
        prn = urbanSV(svInd);
        plot3(i,svInd,urbanCN0(i,svInd),'o','MarkerSize',5)
        hold on
        if i == 1
            legendEntries{end+1} = sprintf('PRN %d', prn);
        end
    end
end
hold off
zlim([0 60]);
ylim([1 length(urbanSV)]);
grid on
title('Urban C/N_0 Plot')
xlabel('Epoch (ms)')
ylabel('Channel')
zlabel('C/N_0 Ratio')
legend(legendEntries, 'Location', 'eastoutside')

%% Open Sky ACF Construction
h = waitbar(0,['Constructing Open Sky ACF ...']);
for i = 1:length(openSkyTck(openSkySV(1)).E)
    waitbar(i/length(openSkyTck(openSkySV(1)).E),h)
    for svInd = 1:length(openSkySV)
        prn = openSkySV(svInd);
        openSkyTck(prn).ACF(i,:) = [openSkyTck(prn).E(i) openSkyTck(prn).E2(i) openSkyTck(prn).E3(i) ...
            openSkyTck(prn).E4(i) openSkyTck(prn).E5(i) openSkyTck(prn).P(i) ...
            openSkyTck(prn).L2(i) openSkyTck(prn).L3(i) openSkyTck(prn).L4(i) ...
            openSkyTck(prn).L5(i) openSkyTck(prn).L(i)];
    end
end
close(h)

%% Open Sky ACF Plot
h = waitbar(0,['Plotting Open Sky ACF ...']);
figure
for i = 1:plotSamplingInterv:length(openSkyTck(openSkySV(1)).E)
    waitbar(i/length(openSkyTck(openSkySV(1)).E),h)
    for svInd = 1:length(openSkySV)
        prn = openSkySV(svInd);
        plot(Spacing(3:2:23),openSkyTck(prn).ACF(i,:))
        hold on
    end
end
hold off
grid on
title('Open Sky Correlation Plot')
xlabel('Time Delay (Chip)')
ylabel('Correlation Value')
close(h)

%% Single Satellite Open Sky ACF Plot
% h = waitbar(0,['Constructing Open Sky ACF for Single Satellite...']);
% figure
% for svInd = 4
%     prn = openSkySV(svInd);
%     for i = 1:plotSamplingInterv:length(openSkyTck(openSkySV(1)).E)
%         waitbar(i/length(openSkyTck(openSkySV(1)).E),h)
%         plot(Spacing(3:2:23),openSkyTck(prn).ACF(i,:))
%         hold on
%     end
% end
% hold off
% grid on
% title(sprintf('Open Sky Correlation Plot - PRN %d', openSkySV(4)))
% xlabel('Time Delay (Chip)')
% ylabel('Correlation Value')
% close(h)

%% Open Sky C/N0 Plot
figure
legendEntries = {};
for i = 1:plotSamplingInterv/10:length(openSkyCN0)
    for svInd = 1:length(openSkySV)
        prn = openSkySV(svInd);
        plot3(i,svInd,openSkyCN0(i,svInd),'o','MarkerSize',5)
        hold on
        if i == 1
            legendEntries{end+1} = sprintf('PRN %d', prn);
        end
    end
end
hold off
zlim([0 60]);
ylim([1 length(openSkySV)]);
grid on
title('Open Sky C/N_0 Plot')
xlabel('Epoch (ms)')
ylabel('Channel')
zlabel('C/N_0 Ratio')
legend(legendEntries, 'Location', 'eastoutside')

% figure
% for svInd = 1:length(openSkySV)
%     plot(1:length(openSkyCN0),openSkyCN0(svInd),'o','MarkerSize',5)
%     figure
% end
% hold off
% zlim([0 60]);
% ylim([1 6]);
% grid on
% title('Open Sky C/N_0 Plot')
% xlabel('Epoch (ms)')
% ylabel('Channel')
% zlabel('C/N_0 Ratio')