function [estusr, dop] = wlspos(prvec,svxyzmat,initpos,tol,el,CN0)
%WLSPOS Compute position from satellite positions and pseudoranges
%	via weighted least squares.
%
%[estusr,dop] = WLSPOS(prvec,svxyzmat,initpos,tol,el,CN0)
%
%INPUTS
%prvec = vector of 'measured' pseudoranges for satellites
%specified in svxyzmat
%svxyzmat(i,1:3) = position of satellite i in user defined
%                   cartesian coordinates.
%initpos = optional argument. Initial 'estimate' of user state:
%           three-dimensional position and clock offset
%           (in user defined coordinates). Used to speed up
%           iterative solution. Initial clock offset is
%           optional with default value = 0.
%tol = optional argument. Tolerance value used to determine
%           convergence of iterative solution. Default value = 1e-3
%el  = elevations of the visible satellites in degrees.
%CN0 = carrier to noise density ratio of the visible satellites.
%
%OUTPUTS
%estusr(1:3) = estimated user x, y, and z coordinates
%estusr(4) = estimated user clock offset
%	Note: all four elements of estusr are in the same units
%           as those used in prvec
%  L5/E5a/B2a pseudorange measurements in the urban area", Advances in Space Research, 2020

% Weighting threshold coefficients
T = 50;
F = 20;
A = 50;
a = 30;

if nargin<4,tol=1e-3;end
if nargin<3,initpos=[0 0 0 0];end
if nargin<2,error('insufficient number of input arguments'),end
[m,n]=size(initpos);
if m>n, estusr=initpos';else,estusr=initpos;end
if max(size(estusr))<3,
    error('must define at least 3 dimensions in INITPOS')
end
if max(size(estusr))<4,estusr=[estusr 0];end
numvis=max(size(svxyzmat));
beta=[1e9 1e9 1e9 1e9];

if any(isinf(CN0))
    W = eye(numvis,numvis);
else
    w = zeros(numvis,numvis);
    for i = 1:numvis    
        if CN0(numvis)>= T && CN0(numvis) ~=Inf
            tau = 1;
        else
            term1 = 1/(sind(el(i))^2);
            term2 = 10^(-(CN0(i)-T)/a);
            term3a = (A/(10^(-(F-T)/a))) - 1;
            term3b = (CN0(i)-T)/(F-T);
            term3 = term3a*term3b + 1;
            tau = term1*(term2*term3);
            w(i,i) = tau;
        end
    end
    W = inv(w);
end

maxiter=10;
iter=0;
% while ((iter<maxiter)&&(norm(beta)>tol)),
while ( (norm(beta)>tol)),
    for N = 1:numvis,
        pr0 = norm(svxyzmat(N,:)-estusr(1:3));
        y(N,1) = prvec(N) - pr0 - estusr(4);
    end,
    H = hmat(svxyzmat,estusr(1:3));
    beta = inv(H'*W*H)*H'*W*y;
    estusr=estusr+beta';
    iter=iter+1;
end

% Calculate DOP, XUBING, 20180914
dop = zeros(1,4);
Q = inv(H'*H);
dop(1)  = sqrt(trace(Q));                       % GDOP
dop(2)  = sqrt(Q(1,1) + Q(2,2) + Q(3,3));       % PDOP
dop(3)  = sqrt(Q(1,1) + Q(2,2));                % HDOP
dop(4)  = sqrt(Q(3,3));                         % VDOP
dop(5)  = sqrt(Q(4,4));                         % TDOP


