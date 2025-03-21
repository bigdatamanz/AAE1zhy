function [TckResultCT_pos, navSolutionsCT] = trackingCT_POS_updated(file,signal,track,cmn, Acquired,TckResult_Eph, cnslxyz,eph,sbf,solu)
%Purpose:
%   Scalar tracking and positioning. Positioning and tracking are
%   implemented at the same time.
%   Conventional tracking and positioning using EKF and WLS
%Inputs:
%	file        - parameters related to the data file to be processed,a structure
%	signal   	- parameters related to signals,a structure
%	track     	- parameters related to signal tracking,a structure
%	cmn         - parameters commmonly used,a structure
%	Acquired 	- acquisition results
%   TckResult_Eph - Tracking results that used for decoding eph., which
%   also contains information like indexes for first nav. bit transition, subframe,
%   absolute sample index in the IF file for each ms, etc
%	cnslxyz 	- initial position in ECEF coordinate
%	eph         - ephemeris
%	sbf         - parameters used for pseudorange estimation
%
%Outputs:
%	TckResultCT         - conventional tracking results
%	navSolutionsCT   	- navigation solutions in conventional tracking mode
%--------------------------------------------------------------------------
%                           GPSSDR_vt v1.0
%
% Written by B. XU and L. T. HSU

%%
sv_clk              = zeros(1,32);
clkBias_kf         	= 0;
usr_clk_wls         = 0;
clkDrift            = 0;
oldclkDrift         = 0;
estusr              = zeros(1,3);
estusr_wls          = cnslxyz;% zeros(1,3);
estusr_kf           = [cnslxyz clkBias_kf];%
clkDrift_kf         = clkDrift;
estVel              = solu.iniVel;
oldEstVel          	= estVel;
num_state           = 8;
CN0_CT              = Inf(1,length(Acquired.sv));

Spacing = 0.6:-0.05:-0.6;

sv      = Acquired.sv ;
f0      = signal.codeFreqBasis;
fs      = signal.Fs ;
pdi     = track.pdi;
t       = signal.ms;
svlength    = length(sv);
datalength  = track.msPosCT;

% Kalman Filter Parameter
num_state   = 8;

% error state vector
error_state = zeros(num_state,1);
total_state = [cnslxyz(1:3),zeros(1,5)]';%zeros(num_state,1);

% system transition matrix
Dynamic_Model = diag(zeros(1,num_state));
Dynamic_Model(1,4)  = 1;
Dynamic_Model(2,5)  = 1;
Dynamic_Model(3,6)  = 1;
Dynamic_Model(7,8)  = 1;
Transistion_Matrix  = eye(length(error_state)) + Dynamic_Model*pdi*t;

% error covariance matrix
state_cov = 1e5*diag([1e-1,1e-1,1e-1,1e-1,1e-1,1e-1,1e0,1e0]);

% process (System) noise noise covariance matrix
process_noise(1:3,1:3) = diag(ones(1,3)*2e-1);
process_noise(4:6,4:6) = diag(ones(1,3)*1e-1);
process_noise(7,7) = 1e-1;
process_noise(8,8) = 1e-2;

% measurement noise covariance matrix
mesurement_noise(1:svlength,1:svlength) = eye(svlength)*3e-1;
mesurement_noise(svlength+1:2*svlength,svlength+1:2*svlength) = eye(svlength)*1e-1;

% parameters for measurement noise variance update
flag_corrCovEst2 = 1;
counterUptR = 0;
counter_r = 0;
thresUptR = 200/pdi;

% Calculate filter coefficient values
[tau1code, tau2code] = calcLoopCoef(track.DLLBW,track.DLLDamp,track.DLLGain);
[tau1carr, tau2carr] = calcLoopCoef(track.PLLBW,track.PLLDamp,track.PLLGain);
%

% initialize tracking parameters using acquisition results
for svindex = 1:length(sv)
    prn                     = sv(svindex);
    codetemp                = generateCAcode(prn);
    Code(svindex,:)         = [codetemp(end) repmat(codetemp,1,pdi) codetemp(1)];
    AcqCodeDelay(svindex)   = Acquired.codedelay(svindex);
    %     file_ptr(svindex)       = signal.Sample - AcqCodeDelay(svindex) -1 + file.skip *fs*t + 0;
    %     file_ptr(svindex)       = signal.Sample - AcqCodeDelay(svindex) +1 + file.skip *fs*t + 0;   % 29/04/2020
    
    % 29/04/29, for each channel, move the file pointer to the first
    % subframe (not subframe 1), to ensure 20 ms T_coh and do positioning
    file_ptr(svindex)       = (signal.Sample - AcqCodeDelay(svindex) +1 ...
        + file.skip *fs*t ... 
        )*file.dataPrecision*file.dataType;
    %     file_ptr(svindex)       = (signal.Sample - AcqCodeDelay(svindex) +1 ...
    %                                   + file.skip *fs*t ...
    %                                   + sbf.nav1(prn) *fs*t ...
    %                                   + eph(prn).sfb(1)*20*fs*t ...
    %                                   )*file.dataPrecision*file.dataType;
    
    carrFreq(svindex)       = Acquired.fineFreq(svindex);
    AcqFreq(svindex)        = Acquired.fineFreq(svindex);
    
    oldcodedelay_pos(svindex) = 0;
    oldabsoluteSample_pos(svindex) = 0;
end

% parameters for C/N0 estimate
snrIndex	= ones(1,svlength);
K           = 20;
flag_snr    = ones(1,svlength); % flag to calculate C/N0
index_int   = zeros(1,svlength);

eph_idx     = ones(1,svlength);

corrUpdateSec   = 0.1;
corrUpt         = corrUpdateSec/(pdi*t);
counter_corr    = corrUpt-1 * ones(svlength,1);

% Tracking parameters
carrNco      = zeros(1,svlength);
oldCarrNco  = zeros(1,svlength);
oldCarrError       = zeros(1,svlength);
codeNco         = zeros(1,svlength);
code_outputLast     = zeros(1,svlength);
DLLdiscriLast       = zeros(1,svlength);
remChip             = zeros(1,svlength);
codeFreq            = ones(1,svlength)*f0;
remCarrPhase        = zeros(1,svlength);
carrError           = zeros(1,svlength);
codeError           = zeros(1,svlength);
delayValue          = zeros(svlength,datalength/pdi);

%%
localTime = inf;

% Find start and end of measurement point locations in IF signal stream with available
% measurements
sampleStart = zeros(1, svlength);
sampleEnd = inf(1, svlength);

for channelNr = 1:svlength
    prn = sv(channelNr);
    sampleStart(channelNr) = ...
        TckResult_Eph(prn).absoluteSample(sbf.nav1(prn)+eph(prn).sfb(1)*20); % first subframe, in unit of ms
    
    sampleEnd(channelNr) = TckResult_Eph(prn).absoluteSample(end);
end
sampleStartMea = max(sampleStart) + 1; % Now, in  unit of sample
sampleEndMea = min(sampleEnd) - 1;

%--- Measurement step in unit of IF samples -------------------------------
measSampleStep = fix(signal.Fs * solu.navSolPeriod/1000)*file.dataType;%file.dataType;

% flag for position. When the file pointers in all tracking channels exceed
% the current measurement point (in samples), we do positioning
flg_pos = zeros(1,svlength);

% Index for positioning
posIndex = 0;

%%
h = waitbar(0,['Conventional Tracking, Length: ',num2str(datalength),' ms,', '  Please wait...']);
tic

%%
for msIndex = 1: datalength/pdi % Note that for pdi > 1ms, the index is still denoted as msIndex. 30/04/2020, BING XU
    waitbar(msIndex/(datalength/pdi),h)
    for svindex = 1 :svlength
        prn = sv(svindex);
        
        % read raw data file
        codePhaseStep(svindex) = codeFreq(svindex)/signal.Fs;
        numSample = ceil((signal.codelength*pdi-remChip(svindex))/codePhaseStep(svindex));
        
        delayValue(svindex,msIndex) = numSample - signal.Sample*pdi;
        
        fseek(file.fid, file_ptr(svindex),'bof');
        
        if file.dataPrecision == 2
            rawsignal = fread(file.fid,numSample*file.dataType,'int16')';
            sin_rawsignal = rawsignal(1:2:length(rawsignal));
            cos_rawsignal = rawsignal(2:2:length(rawsignal));
            rawsignal = (sin_rawsignal - mean(sin_rawsignal)) + 1i.*(cos_rawsignal-mean(cos_rawsignal));
        else
            rawsignal = fread(file.fid,numSample*file.dataType,'int8')'; %
            rawsignal = rawsignal(1:2:length(rawsignal)) + 1i*rawsignal(2:2:length(rawsignal));% For NSL STEREO LBand only
        end
        
        file_ptr(svindex)   = file_ptr(svindex) + numSample*file.dataType;  %%%%%%   
        
        %% spacing = -0.6:0.05:0.6
        t_CodeEarly       = (0 + Spacing(3) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(3) + remChip(svindex));
        t_CodePrompt      = (0 + Spacing(13) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(13) + remChip(svindex));
        t_CodeLate        = (0 + Spacing(23) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(23) + remChip(svindex));
        
        CodeEarly      = Code(svindex,(ceil(t_CodeEarly) + 1));
        CodePrompt     = Code(svindex,(ceil(t_CodePrompt) + 1));
        CodeLate       = Code(svindex,(ceil(t_CodeLate) + 1));

        % Multicorrelators
        if track.multiCorr == 1;
            t_CodeE2       = (0 + Spacing(5) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(5) + remChip(svindex));
            t_CodeE3       = (0 + Spacing(7) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(7) + remChip(svindex));
            t_CodeE4       = (0 + Spacing(9) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(9) + remChip(svindex));
            t_CodeE5       = (0 + Spacing(11) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(11) + remChip(svindex));
            t_CodeL2      = (0 + Spacing(15) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(15) + remChip(svindex));
            t_CodeL3        = (0 + Spacing(17) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(17) + remChip(svindex));
            t_CodeL4        = (0 + Spacing(19) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(19) + remChip(svindex));
            t_CodeL5        = (0 + Spacing(21) + remChip(svindex)) : codePhaseStep(svindex) : ((numSample -1) * codePhaseStep(svindex) + Spacing(21) + remChip(svindex));
    
            CodeE2      = Code(svindex,(ceil(t_CodeE2) + 1));
            CodeE3      = Code(svindex,(ceil(t_CodeE3) + 1));
            CodeE4      = Code(svindex,(ceil(t_CodeE4) + 1));
            CodeE5      = Code(svindex,(ceil(t_CodeE5) + 1));
            CodeL2       = Code(svindex,(ceil(t_CodeL2) + 1));
            CodeL3       = Code(svindex,(ceil(t_CodeL3) + 1));
            CodeL4       = Code(svindex,(ceil(t_CodeL4) + 1));
            CodeL5       = Code(svindex,(ceil(t_CodeL5) + 1));
        end

        %%
        remChip(svindex) = t_CodePrompt(numSample) + codePhaseStep(svindex) - signal.codelength*pdi;
        
        CarrTime = (0:numSample)./signal.Fs;
        Wave = 2*pi*((carrFreq(svindex)).*CarrTime) + remCarrPhase(svindex);
        remCarrPhase(svindex) = rem(Wave(numSample+1), 2*pi);
        carrsig = exp(1i.* Wave(1:numSample));
        InphaseSignal    = imag(rawsignal .* carrsig);
        QuadratureSignal = real(rawsignal .* carrsig);        
        
        %%
        E_i      = sum(CodeEarly    .*InphaseSignal);
        E_q      = sum(CodeEarly    .*QuadratureSignal);
        P_i      = sum(CodePrompt   .*InphaseSignal);
        P_q      = sum(CodePrompt   .*QuadratureSignal);
        L_i     = sum(CodeLate     .*InphaseSignal);
        L_q     = sum(CodeLate     .*QuadratureSignal);

        % Multi corrrelator IQ
        if track.multiCorr == 1;
            E2_i     = sum(CodeE2    .*InphaseSignal);
            E2_q     = sum(CodeE2    .*QuadratureSignal);
            E3_i     = sum(CodeE3    .*InphaseSignal);
            E3_q     = sum(CodeE3    .*QuadratureSignal);
            E4_i     = sum(CodeE4    .*InphaseSignal);
            E4_q     = sum(CodeE4    .*QuadratureSignal);
            E5_i     = sum(CodeE5    .*InphaseSignal);
            E5_q     = sum(CodeE5    .*QuadratureSignal);
            L2_i     = sum(CodeL2     .*InphaseSignal);
            L2_q     = sum(CodeL2     .*QuadratureSignal);
            L3_i     = sum(CodeL3     .*InphaseSignal);
            L3_q     = sum(CodeL3     .*QuadratureSignal);
            L4_i     = sum(CodeL4     .*InphaseSignal);
            L4_q     = sum(CodeL4     .*QuadratureSignal);
            L5_i     = sum(CodeL5     .*InphaseSignal);
            L5_q     = sum(CodeL5     .*QuadratureSignal);
        end

        % Calculate CN0
        if (flag_snr(svindex) == 1)
            index_int(svindex) = index_int(svindex) + 1;
            Zk(svindex,index_int(svindex)) = P_i^2 + P_q^2;
            if mod(index_int(svindex),K) == 0
                meanZk  = mean(Zk(svindex,:));
                varZk   = var(Zk(svindex,:));
                NA2     = sqrt(meanZk^2-varZk);
                varIQ   = 0.5 * (meanZk - NA2);
                CN0_CT(snrIndex(svindex),svindex) =  abs(10*log10(1/(1*t*pdi) * NA2/(2*varIQ)));
                index_int(svindex)  = 0;
                snrIndex(svindex)   = snrIndex(svindex) + 1;
            end
        end
        
        % Implement code loop filter and generate NCO command
        E = sqrt(E_i^2+E_q^2);
        L = sqrt(L_i^2+L_q^2);
        P = sqrt(P_i^2+P_q^2);

        % Multicorrelator ACF
        if track.multiCorr == 1
            E2 = sqrt(E2_i^2+E2_q^2);
            E3 = sqrt(E3_i^2+E3_q^2);
            E4 = sqrt(E4_i^2+E4_q^2);
            E5 = sqrt(E5_i^2+E5_q^2);
            L2 = sqrt(L2_i^2+L2_q^2);
            L3 = sqrt(L3_i^2+L3_q^2);
            L4 = sqrt(L4_i^2+L4_q^2);
            L5 = sqrt(L5_i^2+L5_q^2);

            % plot(Spacing(3:2:23),[E,E2,E3,E4,E5,P,L2,L3,L4,L5,L]) %%%%%%%%%%% ACF Plotting
            % hold on
        % else
            % plot(Spacing(3:10:23),[E,P,L])
            % hold on

        end
        codeError(svindex) = 0.5*(E-L)/(E+L);  % DLL discriminator
        codeNco(svindex) = code_outputLast(svindex) + (tau2code/tau1code)*(codeError(svindex)...
            - DLLdiscriLast(svindex)) + codeError(svindex)* ((pdi*t)/tau1code);
        DLLdiscriLast(svindex) = codeError(svindex);
        code_outputLast(svindex) = codeNco(svindex);
                 %codeFreq(svindex) = signal.codeFreqBasis - codeNco(svindex);
        codeFreq(svindex) = signal.codeFreqBasis + codeNco(svindex);
        
        % PLL discriminator
        carrError(svindex) = atan(P_q/P_i)/(2*pi);  % PLL discriminator
        carrNco(svindex) = oldCarrNco(svindex) + (tau2carr/tau1carr)*(carrError(svindex) ...
            - oldCarrError(svindex)) + carrError(svindex) * ((pdi*t)/tau1carr);
        oldCarrNco(svindex) = carrNco(svindex);
        oldCarrError(svindex) = carrError(svindex);
        carrFreq(svindex)  = AcqFreq(svindex) + carrNco(svindex);  % Modify carrier freq

        % KF Measurements
        if solu.mode == 2
            measPRZ(svindex) = codeError(svindex)*cmn.cSpeed/codeFreq(svindex);
            measPRR(svindex)	= (carrFreq(svindex) - signal.IF)*cmn.cSpeed/signal.Fc;
            % measDoppler(svindex) = carrFreq(svindex) - signal.IF;
        end
        
        %% Data Recording
        TckResultCT(prn).E_i(msIndex) = E_i;
        TckResultCT(prn).E_q(msIndex) = E_q;
        TckResultCT(prn).P_i(msIndex) = P_i;
        TckResultCT(prn).P_q(msIndex) = P_q;
        TckResultCT(prn).L_i(msIndex) = L_i;
        TckResultCT(prn).L_q(msIndex) = L_q;

        % ACF recording
        TckResultCT(prn).E(msIndex) = E;
        TckResultCT(prn).L(msIndex) = L;
        TckResultCT(prn).P(msIndex) = P;
        if track.multiCorr == 1
            TckResultCT(prn).E2(msIndex) = E2;
            TckResultCT(prn).E3(msIndex) = E3;
            TckResultCT(prn).E4(msIndex) = E4;
            TckResultCT(prn).E5(msIndex) = E5;
            TckResultCT(prn).L2(msIndex) = L2;
            TckResultCT(prn).L3(msIndex) = L3;
            TckResultCT(prn).L4(msIndex) = L4;
            TckResultCT(prn).L5(msIndex) = L5;
        end
        
        TckResultCT(prn).carrError(msIndex)       = carrError(svindex);
        TckResultCT(prn).codeError(msIndex)       = codeError(svindex);
        TckResultCT(prn).codeFreq(msIndex)        = codeFreq(svindex);
        TckResultCT(prn).carrFreq(msIndex)        = carrFreq(svindex);
        TckResultCT(prn).numSample(msIndex)       = numSample;
        TckResultCT(prn).remChip(msIndex)         = remChip(svindex);
        TckResultCT(prn).remCarrPhase(msIndex)    = remCarrPhase(svindex);
        TckResultCT(prn).absoluteSample(msIndex)  = ftell(file.fid);
        TckResultCT(prn).absoluteSampleCodedelay(msIndex)  = mod(TckResultCT(prn).absoluteSample(msIndex)/(file.dataPrecision*file.dataType),fs*t );
        TckResultCT(prn).codedelay(msIndex)       = signal.Sample - AcqCodeDelay(svindex) +1 + sum(delayValue(svindex,(1:msIndex)));
        TckResultCT(prn).codedelay2(msIndex)      = mod( TckResultCT(prn).absoluteSample(msIndex)/(file.dataPrecision*file.dataType),fs*t );
        TckResultCT(prn).delayValue(msIndex)      = delayValue(svindex,msIndex);
        
        
        
    end % end for svindex in Tracking
    
    
    %%
    % Position index of current measurement time in IF signal stream
    % (in unit IF signal sample point)
    currMeasSample = sampleStartMea + measSampleStep*posIndex;
    
    for svIndex=1:svlength
        prn = sv(svIndex);
        if TckResultCT(prn).absoluteSample(msIndex) > currMeasSample
            flg_pos(svIndex) = 1;
        else
            flg_pos(svIndex) = 0;
        end
    end
    
    %%
    if sum(flg_pos) == svlength  
        posIndex = posIndex + 1;
        for svIndex=1:svlength
            prn = sv(svIndex);
            
            % Find index of I_P stream whose integration contains current
            % measurment point location
            for index = 1: length(TckResultCT(prn).absoluteSample)
                if(TckResultCT(prn).absoluteSample(index) > currMeasSample )
                    break
                end
            end
            index = index - 1;
            
            % Update the phasestep based on code freq and sampling frequency
            codePhaseStepX = TckResultCT(prn).codeFreq(index)/signal.Fs;
            
            codePhaseMeas(svIndex) = TckResultCT(prn).remChip(index) + ...
                codePhaseStepX*((currMeasSample - TckResultCT(prn).absoluteSample(index))/file.dataType);%file.dataType
            
            transmitTime(svIndex) = codePhaseMeas(svIndex)/signal.codelength/1000 + ... %TckResultCT(prn).codedelay(msIndex)/(signal.Fs/1000) 
                (index - (sbf.nav1(prn)+eph(prn).sfb(1)*20))/1000 + ...
                eph(prn).TOW(1); 
%              transmitTime(svIndex) = codePhaseMeas(svIndex)/signal.codelength/1000 + ... %TckResultCT(prn).codedelay(msIndex)/(signal.Fs/1000) 
%                  (index - (sbf.nav1(prn)))/1000 + ...
%                  eph(prn).TOW(1);
        end
      
        % At first time of fix, local time is initialized by transmitTime and
        % settings.startOffset
        if (localTime == inf)
            maxTime   = max(transmitTime);
            i = 1;
            while abs(maxTime) > 1.1*abs(mean(transmitTime))
                transTimeSort = sort(transmitTime,'descend');
                maxTime = transTimeSort(i+1)
            end
            localTime = maxTime + 70/1000; % 68 ms is an assumed travel time
        end
        pseudorange = (ones(1,svlength).*localTime - transmitTime)*cmn.cSpeed;
        
        %
        usr_clk = usr_clk_wls ;%%%
        estusr = estusr_wls;%%%
        
        for svindex = 1 : svlength
            prn = sv(svindex);
            
            tot_est_pos(svindex) = transmitTime(svindex);% ...
                                                 %+ (1/cmn.cSpeed)*sv_clk(prn);
            
            % find the sv pos in ECEF at the time of transmision
            [svxyz(svindex,:), sv_vel(svindex,:), sv_clk(prn), sv_clk_vel(prn), grpdel] = ...
                svPosVel(prn,eph,tot_est_pos(svindex),eph_idx(svindex));
            
            % C/A-code pseudorange corrected for satellite clock (in meters) and Tgd(in sec)
            prvec(svindex)      = pseudorange(svindex) + sv_clk(prn) - grpdel*cmn.cSpeed;% -sv_clk(prn);
            
            % Adjust satellite position coordinates for earth rotation correction
            svxyzr(svindex,:)   = erotcorr(svxyz(svindex,:),prvec(svindex));
            
            % tropospheric and ionospheric delay correction
            counter_corr(svindex) = counter_corr(svindex) + 1;
            if counter_corr(svindex) ==  corrUpt
                svenu           = xyz2enu(svxyzr(svindex,:), estusr(1:3));%
                el_rad(svindex) = atan(svenu(3)/norm(svenu(1:2)));
                %             az_rad(svindex) = (pi/2)-atan2(svenu(1),svenu(2));
                az_rad(svindex) =  atan2(svenu(1),svenu(2));
                az(svindex)     = az_rad(svindex)*180/pi;
                el(svindex)     = el_rad(svindex)*180/pi;
                temp            = xyz2llh(estusr(1:3));
                user_ll         = [temp(1:2).*180/pi temp(3)];
                if solu.flag_spaceUsr == 0
                    ionodel(svindex)        = ionocorr(tot_est_pos(svindex),svxyzr(svindex,:), estusr(1:3));
                    tropodel_unb3(svindex)  = abs(trop_UNB3(cmn.doy,user_ll(1),user_ll(3),el(svindex))); %%%%%%%%%%%%%%%%%%%%%%%%% Turn off for spaceborne RCV
                else
                    ionodel(svindex)        = 0; %%%%%%%%%%%%%%%%%%%%%%%%% zero for spaceborne RCV
                    tropodel_unb3(svindex)  = 0; %%%%%%%%%%%%%%%%%%%%%%%%% zero for spaceborne RCV
                end
                counter_corr(svindex)   = 0;
            end
            
            prvec(svindex) = prvec(svindex) - ionodel(svindex) - tropodel_unb3(svindex); % sign of iono. and trop. error?
           % prvec(svindex) = prvec(svindex) - tropodel_unb3(svindex);
        end % for svindex=1:svlength
        
        
        %% Record Ppseudorange measurement 
        navSolutionsWLS.rawPseudorange(posIndex,:) = pseudorange ;
        navSolutionsWLS.prvec(posIndex,:) = prvec;
        
        %% Position cal using LS method
        if solu.mode == 1
            [estusr_wls, dop]       = wlspos(prvec,svxyzr,estusr_wls,1e-3,el,CN0_CT(end,:));
            [VR, dtRV, ~]     = ...
            LS_SA_code(estusr_wls(1:3)', svxyzr, sv_vel, (carrFreq'), 0.190293672798365, sv_clk_vel(sv));%-signal.IF
        elseif solu.mode == 2
            [estusr_wls, VR, dtRV]  = kfpos(prvec,svxyzr,sv_vel,sv_clk_vel(sv),estusr_kf,oldEstVel,clkDrift,track.pdi,num_state,measPRZ,measPRR,cnslxyz,error_state,state_cov);
            estusr_kf = estusr_wls; % iteration update
            oldEstVel = VR';
            clkDrift = dtRV;
        else
            [estusr_wls, dop]       = olspos(prvec,svxyzr,estusr_wls); % ordinary least square
            [VR, dtRV, ~]     = ...
            LS_SA_code(estusr_wls(1:3)', svxyzr, sv_vel, (carrFreq'), 0.190293672798365, sv_clk_vel(sv));%-signal.IF
        end
        %[estusr_wls, dop]       = olspos(pr_CT_truth(posIndex,:),svxyzr,estusr_wls); % ordinary least square
        % [VR, dtRV, ~]     = ...
        %     LS_SA_code_Vel_xubing(estusr_wls(1:3)', svxyzr, sv_vel, (carrFreq'), 0.190293672798365, sv_clk_vel(sv));%-signal.IF

        % load('FGI_sv.mat')
        % FGI_sv_pos = reshape([sat.gpsl1.channel.Pos],3,[]).';
        % FGI_sv_pos(end-1,:) = [];
        % FGI_sv_vel = reshape([sat.gpsl1.channel.Vel],4,[]).';
        % FGI_sv_vel(end-1,:) = [];
        % FGI_sv_vel(:,end) = [];
        % FGI_doppler = reshape([obs.gpsl1.channel.doppler],1,[]).';
        % FGI_doppler(end-1) = [];
        % [VR, dtRV, ~]     = ...
        %     LS_SA_code_Vel_xubing(solu.iniPos', FGI_sv_pos, FGI_sv_vel, carrFreq'-signal.IF, 0.190293672798365, sv_clk_vel(sv));%-signal.IF
        
        usrenu_wls(posIndex,:)   = xyz2enu(estusr_wls(1:3),cnslxyz);
        usr_clk_wls             = estusr_wls(4);
        
        llh     = xyz2llh(estusr_wls(1:3));
        L_b     = llh(1);
        lamda_b = llh(2);
        C_e_n = [ -sin(lamda_b)           cos(lamda_b)         	 0;...
            -sin(L_b)*cos(lamda_b) -sin(L_b)*sin(lamda_b)	 cos(L_b);...
            -cos(L_b)*cos(lamda_b) -cos(L_b)*sin(lamda_b)	-sin(L_b);];
        usr_velENU(posIndex,:) = C_e_n * VR ;
        
        usrenu_wls(posIndex,:)                 	= xyz2enu(estusr_wls(1:3),cnslxyz);
        usrllh_wls(posIndex,:)                   = xyz2llh(estusr_wls(1:3));
        usrllh_wls(posIndex,1:2)                 = usrllh_wls(posIndex,1:2)*180/pi;
        
        %     navSolutionsWLS.RxTime(msIndex)       = RxTime(msIndex);
        navSolutionsWLS.usrPos(posIndex,:)       = estusr_wls(1:3);
        navSolutionsWLS.usrVel(posIndex,:)       = VR;
        navSolutionsWLS.usrPosENU(posIndex,:)    = usrenu_wls(posIndex,:);
        navSolutionsWLS.usrPosLLH(posIndex,:)    = usrllh_wls(posIndex,:);
        navSolutionsWLS.clkBias(posIndex)        = usr_clk_wls;
        navSolutionsWLS.usrVelENU(posIndex,:)        = usr_velENU(posIndex,:);
        navSolutionsWLS.clkDrift(posIndex)   = dtRV; % m/s
        navSolutionsWLS.satEA(posIndex,:)      = el;
        navSolutionsWLS.satAZ(posIndex,:)      = az;
        navSolutionsWLS.svxyzr(:,:,posIndex)     = svxyzr;
        navSolutionsWLS.codePhaseMeas(posIndex,:) = codePhaseMeas;
        if solu.mode ~= 2
            navSolutionsWLS.DOP(posIndex,:)       = dop;
        end
        %     navSolutionsWLS.test(msIndex,:)      = test;
        
        
        %=== Correct local time by clock error estimation =================
        navSolutionsWLS.localTime(posIndex,:) = localTime;
        localTime = localTime - navSolutionsWLS.clkBias(posIndex)/cmn.cSpeed;%+0.02;
        %navSolutionsWLS.localTime(posIndex,:) = localTime;
        
        %=== Update local time by measurement  step  ====================================
        localTime = localTime + measSampleStep/signal.Fs;
        
       if posIndex == 200
           xx = 0;
       end
        navSolutionsCT = navSolutionsWLS;
        
        if mod(posIndex, 1) == 0 %%%%%%%%%%%%%%%%%%%%%%%
            fprintf('WLS: index = %4d; localTime: %f;  E = %f N = %f U = %f  VE = %f VN = %f VU = %f B = %f D = %f\n\n', ...
                posIndex, localTime, usrenu_wls(posIndex,1),usrenu_wls(posIndex,2),usrenu_wls(posIndex,3),usr_velENU(posIndex,1), usr_velENU(posIndex,2), usr_velENU(posIndex,3), usr_clk_wls, dtRV);
        end

        % if mod(posIndex, 1) == 0 %%%%%%%%%%%%%%%%%%%%%%% Test for spaceborne RCV, positions ECEF replaced llh
        %     fprintf('WLS: index = %4d; localTime: %f;  E = %f N = %f U = %f  VE = %f VN = %f VU = %f B = %f D = %f\n\n', ...
        %         posIndex, localTime, estusr_wls(1),estusr_wls(2),estusr_wls(3),usr_velENU(posIndex,1), usr_velENU(posIndex,2), usr_velENU(posIndex,3), usr_clk_wls, dtRV);
        % end

    end % end for positioning at current measurement epoch
    
end % end for msIndex

close(h);

TckResultCT_pos = TckResultCT;

if solu.mode == 1
    navSolutionsCT_WLS = navSolutionsCT;
    TckResultCT_WLS = TckResultCT_pos;
    CN0_CT_WLS = CN0_CT;
    save(['navSolCT_WLS_',num2str(pdi),'ms_',file.fileName], 'navSolutionsCT_WLS' );
    save(['tckRstCT_WLS_',num2str(pdi),'ms_',file.fileName], 'TckResultCT_WLS','CN0_CT_WLS');
elseif solu.mode == 2
    navSolutionsCT_KF = navSolutionsCT;
    TckResultCT_KF = TckResultCT_pos;
    CN0_CT_KF = CN0_CT;
    save(['navSolCT_KF_',num2str(pdi),'ms_',file.fileName], 'navSolutionsCT_KF' );
    save(['tckRstCT_KF_',num2str(pdi),'ms_',file.fileName], 'TckResultCT_KF','CN0_CT_KF');
else
    save(['navSolCT_',num2str(pdi),'ms_',file.fileName], 'navSolutionsCT' );
    save(['tckRstCT_',num2str(pdi),'ms_',file.fileName], 'TckResultCT_pos','CN0_CT');
end

