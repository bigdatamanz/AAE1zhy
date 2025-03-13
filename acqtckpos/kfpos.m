function [estPosB, estVel, clkDrift] = kfpos(prvec,svxyzPos,svxyzVel,svDrift,initPosB,initVel,initDrift,pdi,numState,measPR,measPRR,cnslxyz,errorStateX,stateCovP)
%KFPOS Compute position from satellite positions and pseudoranges
%	via kalman filter.
%
%[estusr,dop] = KFPOS(prvec,svxyzmat,initPos,tol,el,CN0)
%
%INPUTS
%prvec = vector of 'measured' pseudoranges for satellites
%specified in svxyzmat
%svxyzmat(i,1:3) = position of satellite i in user defined
%                   cartesian coordinates.
%initPos = optional argument. Initial 'estimate' of user state:
%           three-dimensional position and clock offset
%           (in user defined coordinates). Used to speed up
%           iterative solution. Initial clock offset is
%           optional with default value = 0.
%pdi = predetection integration time e.g. 1 ms.
%num_state = number of navigation states, e.g. 8 for PVT; 11 for PVAT.
%
%OUTPUTS
%estusr(1:3) = estimated user x, y, and z coordinates
%estusr(4) = estimated user clock offset
%	Note: all four elements of estusr are in the same units
%           as those used in prvec

%% Kalman Filter Parameter
ms = 1e-3;
c = 299792458;
numvis=max(size(svxyzPos));
Sv = 1;
h0 = 1e-21; % OCXO typical value
h2 = 1e-24; % OCXO typical value
Sf = c^2*(h0/2);
Sg = c^2*2*pi^2*h2;

% Initialisation
dynamicModel = diag(zeros(numState,1));
for i = 1:numState-5
    dynamicModel(i,i+3) = 1;
end
dynamicModel(end-1,end)  = 1;
    
% errorStateX = zeros(numState,1);
    
% F
transitionF  = eye(length(errorStateX)) + dynamicModel * pdi * ms;
if numState == 11
    TAccel = (pdi*ms)^2/2;
    transitionF(1,7) = TAccel;
    transitionF(2,8) = TAccel;
    transitionF(3,9) = TAccel;
end
    
% P
% stateCovP = 1e4*eye(length(errorStateX));
% stateCovP(end-1,end-1) = stateCovP(end-1,end-1)*10;
% stateCovP(end,end) = stateCovP(end,end)*10;
    
% Q
% processNoiseQ(1:3,1:3) = diag(ones(1,3)*2e-1); % pos
% processNoiseQ(4:6,4:6) = diag(ones(1,3)*1e-1); % vel
processNoiseQ(1:3,1:3) = diag(ones(1,3)*Sv*(pdi*ms)^3/3); % pos
processNoiseQ(4:6,4:6) = diag(ones(1,3)*Sv*(pdi*ms)); % vel
processNoiseQ(1:3,4:6) = diag(ones(1,3)*Sv*(pdi*ms)^2/2);% pos-vel upper
processNoiseQ(4:6,1:3) = diag(ones(1,3)*Sv*(pdi*ms)^2/2);% pos-vel lower

if numState == 11
    processNoiseQ(7:8,7:8) = diag(ones(1,2)*1e0); % accel X,Y
    processNoiseQ(9,9) = 1e0; % accel Z
end
% processNoiseQ(end+1,end+1) = 1e-1;
% processNoiseQ(end+1,end+1) = 1e-2;
processNoiseQ(end+1,end+1) = Sf*(pdi*ms) + Sg*(pdi*ms)^3/3;
processNoiseQ(end+1,end+1) = Sg*(pdi*ms);
processNoiseQ(end-1,end) = Sg*(pdi*ms)^2/2;
processNoiseQ(end,end-1) = Sg*(pdi*ms)^2/2;
    
% R
% measNoiseR(1:numvis,1:numvis) = eye(numvis)*3e-2;
% measNoiseR(numvis+1:2*numvis,numvis+1:2*numvis) = eye(numvis)*1e-2;
measNoiseR(1:numvis,1:numvis) = eye(numvis)*3e4;
measNoiseR(numvis+1:2*numvis,numvis+1:2*numvis) = eye(numvis)*1e6;


% H
for i = 1:numvis
    prvecUnit(i,:) = (svxyzPos(i,:)-initPosB(1:3)) / prvec(i);
    
    if numState == 11
        obsModelH(i,:) = [-prvecUnit(i,:) 0 0 0 0 0 0 1 0];
        obsModelH(i+numvis,:) = [0 0 0 -prvecUnit(i,:) 0 0 0 0 1];
    else
        obsModelH(i,:) = [-prvecUnit(i,:) 0 0 0 1 0];
        obsModelH(i+numvis,:) = [0 0 0 -prvecUnit(i,:) 0 1];
    end
end

% Z
for i = 1:numvis
    % preDop(i) = norm([initVel - svxyzVel(i,:)])/c*signal.Fc*cosd(el(i));
    % diffDopZ(i) = preDop(i) - measDop(i);
    predPRR(i) = (initVel - svxyzVel(i,:))*prvecUnit(i,:)';
    diffPRR(i) = predPRR(i) - measPRR(i) - initDrift + svDrift(i);
end
measZ = cat(2,measPR,diffPRR);

%% Kalman Filter
% A priori prediction
errorStateX = transitionF*errorStateX;
stateCovP = transitionF*stateCovP*transitionF' + processNoiseQ;
% A posteriori update
innovResidualY = measZ' - obsModelH*errorStateX;
innovCovS = obsModelH*stateCovP*obsModelH' + measNoiseR;
gainK = stateCovP*obsModelH'*inv(innovCovS);
errorStateX = errorStateX + gainK*innovResidualY;
stateCovP = (eye(numState) - gainK*obsModelH)*stateCovP;

%% Navigation Solutions
estPosB  = [initPosB(1:3) + errorStateX(1:3)' initPosB(4) + errorStateX(end-1)];
estVel   = initVel' + errorStateX(4:6);
clkDrift = initDrift + errorStateX(end);