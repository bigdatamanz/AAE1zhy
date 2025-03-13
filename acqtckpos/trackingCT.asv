function  [TckResultCT, CN0_Eph] = trackingCT(file,signal,track,Acquired)
%Purpose:
%   Perform signal tracking using conventional DLL and PLL
%Inputs:
%	file        - parameters related to the data file to be processed
%	signal      - parameters related to signals,a structure
%	track       - parameters related to signal tracking 
%	Acquired    - acquisition results
%Outputs:
%	TckResultCT	- conventional tracking results, e.g. correlation values in 
%                   inphase prompt (P_i) channel and in qudrature prompt 
%                   channel (P_q), etc.
%--------------------------------------------------------------------------
%                           GPSSDR_vt v1.0
% 
% Written by B. XU and L. T. HSU

%%
Spacing = [-track.CorrelatorSpacing 0 track.CorrelatorSpacing];

[tau1code, tau2code] = calcLoopCoef(track.DLLBW,track.DLLDamp,track.DLLGain);
[tau1carr, tau2carr] = calcLoopCoef(track.PLLBW,track.PLLDamp,track.PLLGain);

datalength = track.msToProcessCT;
delayValue = zeros(length(Acquired.sv),datalength);


svlength    = length(Acquired.sv);
snrIndex	= ones(1,svlength);
K           = 20;
flag_snr    = ones(1,svlength); % flag to calculate C/N0
index_int   = zeros(1,svlength);
pdi     = 1;%track.pdi; % To decode eph., 1ms T_coh is used. 
sv  = Acquired.sv;

for svindex = 1:length(Acquired.sv)
    remChip = 0;
    remPhase=0;
    remSample = 0;
    carrier_output=0; 
    carrier_outputLast=0;
    PLLdiscriLast=0;
    code_output=0;
    code_outputLast=0;
    DLLdiscriLast=0;
    Index = 0;
    skip_loop_update = false; % Flag to indicate if we should skip PLL/DLL updates
    AcqDoppler = Acquired.fineFreq(svindex)-signal.IF;
    AcqCodeDelay = Acquired.codedelay(svindex);
    
    Codedelay = AcqCodeDelay;
    codeFreq = signal.codeFreqBasis;
    carrierFreqBasis = Acquired.fineFreq(svindex);
    carrierFreq = Acquired.fineFreq(svindex);
    
    % set the file position indicator according to the acquired code delay
%     fseek(file.fid,(signal.Sample-AcqCodeDelay-1+file.skip*signal.Sample)*file.dataPrecision*file.dataType,'bof');  %
    fseek(file.fid,(signal.Sample-AcqCodeDelay+1 + file.skip*signal.Sample)*file.dataPrecision*file.dataType,'bof');  %  29/04/2020
%     fseek(file.fid,(AcqCodeDelay-1+file.skip*signal.Sample)*file.dataPrecision*file.dataType,'bof');  %
    
    Code = generateCAcode(Acquired.sv(svindex));
    Code = [Code(end) Code Code(1)];
    
    h = waitbar(0,['Ch:',num2str(svindex),' Please wait...']);
    
    for IndexSmall = 1: datalength 
        waitbar(IndexSmall/datalength)
        Index = Index + 1;
        
        
        remSample = ((signal.codelength-remChip) / (codeFreq/signal.Fs));
        numSample = round((signal.codelength-remChip)/(codeFreq/signal.Fs));%ceil
        delayValue(svindex,IndexSmall) = numSample - signal.Sample;
        
        % Default values in case we need to skip this iteration
        E_i = 0; E_q = 0;
        P_i = 0; P_q = 0;
        L_i = 0; L_q = 0;
        DLLdiscri = 0;
        PLLdiscri = 0;
        
        % Read signal data
        if file.dataPrecision == 2
            rawsignal = fread(file.fid,numSample*file.dataType,'int16')'; 
            sin_rawsignal = rawsignal(1:2:length(rawsignal));
            cos_rawsignal = rawsignal(2:2:length(rawsignal));
            rawsignal0DC = sin_rawsignal - mean(sin_rawsignal) + 1i*(cos_rawsignal-mean(cos_rawsignal));
        else
            rawsignal0DC = fread(file.fid,numSample*file.dataType,'int8')';
            if file.dataType == 2
            rawsignal0DC = rawsignal0DC(1:2:length(rawsignal0DC)) + 1i*rawsignal0DC(2:2:length(rawsignal0DC));% For NSL STEREO LBand only 
            end
        end
        
        % Get actual length of data read (may be less than requested)
        actual_length = length(rawsignal0DC);
        
        % Debug: Print detailed info about reading data
        % fprintf('Debug Info for SV %d, Index %d:\n', Acquired.sv(svindex), IndexSmall);
        % fprintf('  Size of rawsignal0DC: [%d %d]\n', size(rawsignal0DC, 1), size(rawsignal0DC, 2));
        % fprintf('  numSample = %d, actual_length = %d\n', numSample, actual_length);
        
        % Check if actually read any data
        if actual_length == 0
            fprintf('  WARNING: No data read (rawsignal0DC is empty)! Skipping this iteration.\n');
            % Skip this iteration and continue with the next one
            continue;
        end
        
        % Check if there is a large discrepancy between requested and actual data length
        if actual_length < numSample * 0.7  % If we got less than 70% of requested samples
            fprintf('  WARNING: Significant discrepancy between requested (%d) and actual (%d) data length! Skipping this iteration.\n', numSample, actual_length);
            
            % Set a flag to indicate we're skipping PLL and DLL updates
            skip_loop_update = true;
            
            % Still record the default tracking results to maintain data continuity
            TckResultCT(Acquired.sv(svindex)).P_i(Index)            = P_i;
            TckResultCT(Acquired.sv(svindex)).P_q(Index)            = P_q;
            TckResultCT(Acquired.sv(svindex)).E_i(Index)            = E_i;
            TckResultCT(Acquired.sv(svindex)).E_q(Index)            = E_q;
            TckResultCT(Acquired.sv(svindex)).L_i(Index)            = L_i;
            TckResultCT(Acquired.sv(svindex)).L_q(Index)            = L_q;
            TckResultCT(Acquired.sv(svindex)).PLLdiscri(Index)      = PLLdiscri;
            TckResultCT(Acquired.sv(svindex)).DLLdiscri(Index)      = DLLdiscri;
            TckResultCT(Acquired.sv(svindex)).codeFreq(Index)       = codeFreq;
            TckResultCT(Acquired.sv(svindex)).doppler(Index)        = carrierFreq - carrierFreqBasis;
            TckResultCT(Acquired.sv(svindex)).codedelay(Index)      = Codedelay;
            
            % Skip the rest of this iteration
            continue;
        end
        
        % Reset the loop update flag for normal processing
        skip_loop_update = false;
        
        % Use actual length instead of numSample for code and carrier generation
        actual_samples = actual_length - 1; % For array indexing
        
        t_CodeEarly    = (0 + Spacing(1) + remChip) : codeFreq/signal.Fs : ((actual_samples) * (codeFreq/signal.Fs) + Spacing(1) + remChip);
        t_CodePrompt   = (0 + Spacing(2) + remChip) : codeFreq/signal.Fs : ((actual_samples) * (codeFreq/signal.Fs) + Spacing(2) + remChip);
        t_CodeLate     = (0 + Spacing(3) + remChip) : codeFreq/signal.Fs : ((actual_samples) * (codeFreq/signal.Fs) + Spacing(3) + remChip);
        
        % Check if t_Code arrays are empty
        if isempty(t_CodePrompt)
            fprintf('  ERROR: Code time arrays are empty! Skipping this iteration.\n');
            continue;
        end
        
        CodeEarly      = Code(ceil(t_CodeEarly) + 1);
        CodePrompt     = Code(ceil(t_CodePrompt) + 1);
        CodeLate       = Code(ceil(t_CodeLate) + 1);
        
        % Check for valid code phase
        if isempty(t_CodePrompt)
            fprintf('  ERROR: t_CodePrompt is empty! Using previous remChip value.\n');
        else
            % Use actual length of t_CodePrompt for calculating remChip
            last_idx = length(t_CodePrompt);
            if last_idx > 0
                remChip = (t_CodePrompt(last_idx) + codeFreq/signal.Fs) - signal.codeFreqBasis*signal.ms;
            else
                fprintf('  WARNING: t_CodePrompt is empty, cannot update remChip!\n');
            end
        end
        
        % Use actual_length instead of numSample for carrier wave generation
        CarrTime = (0 : actual_length-1)./signal.Fs;
        Wave     = (2*pi*(carrierFreq .* CarrTime)) + remPhase;  
        
        % Check if Wave is empty before accessing end element
        if isempty(Wave)
            fprintf('  ERROR: Wave array is empty! Using previous remPhase value.\n');
            % Don't update remPhase if Wave is empty
        else
            remPhase = rem(Wave(end), 2*pi);
        end
        
        carrsig = exp(1i.* Wave);
        
        % Debug: Print size information for arrays
        % fprintf('  Size of Wave: [%d %d]\n', size(Wave, 1), size(Wave, 2));
        % fprintf('  Size of carrsig: [%d %d]\n', size(carrsig, 1), size(carrsig, 2));
        
        % Check if sizes are compatible - should not be needed now but keeping as a safety check
        if length(rawsignal0DC) ~= length(carrsig)
            fprintf('  WARNING: Arrays have incompatible sizes! Adjusting...\n');
            % Make the arrays the same length by truncating the longer one
            minLength = min(length(rawsignal0DC), length(carrsig));
            if minLength == 0
                fprintf('  ERROR: One of the arrays has zero length! Skipping this iteration.\n');
                continue;
            end
            rawsignal0DC = rawsignal0DC(1:minLength);
            carrsig = carrsig(1:minLength);
            fprintf('  Arrays adjusted to length: %d\n', minLength);
        end
        
        InphaseSignal    = imag(rawsignal0DC .* carrsig);
        QuadratureSignal = real(rawsignal0DC .* carrsig);
        
        % Make sure all vectors have compatible lengths
        codeLength = length(InphaseSignal);
        if length(CodeEarly) ~= codeLength
            fprintf('  Adjusting code vectors to match signal length (%d)...\n', codeLength);
            if length(CodeEarly) > codeLength
                CodeEarly = CodeEarly(1:codeLength);
                CodePrompt = CodePrompt(1:codeLength);
                CodeLate = CodeLate(1:codeLength);
            else
                % If code vectors are shorter, truncate the signals
                fprintf('  NOTE: Code vectors are shorter than signals, truncating signals\n');
                codeLength = length(CodeEarly);
                InphaseSignal = InphaseSignal(1:codeLength);
                QuadratureSignal = QuadratureSignal(1:codeLength);
            end
        end
        
        E_i  = sum(CodeEarly    .*InphaseSignal);  E_q = sum(CodeEarly    .*QuadratureSignal);
        P_i  = sum(CodePrompt   .*InphaseSignal);  P_q = sum(CodePrompt   .*QuadratureSignal);
        L_i  = sum(CodeLate     .*InphaseSignal);  L_q = sum(CodeLate     .*QuadratureSignal);
        
        
        
                
        % Calculate CN0
        flag_snr(svindex)=1;
        if (flag_snr(svindex) == 1)
            index_int(svindex) = index_int(svindex) + 1;
            Zk(svindex,index_int(svindex)) = P_i^2 + P_q^2;
            if mod(index_int(svindex),K) == 0
                meanZk  = mean(Zk(svindex,:));
                varZk   = var(Zk(svindex,:));
                NA2     = sqrt(meanZk^2-varZk);
                varIQ   = 0.5 * (meanZk - NA2);
                CN0_Eph(snrIndex(svindex),svindex) =  abs(10*log10(1/(1*signal.ms*pdi) * NA2/(2*varIQ)));
                index_int(svindex)  = 0;
                snrIndex(svindex)   = snrIndex(svindex) + 1;
            end
        end
        
        % DLL
        E               = sqrt(E_i^2+E_q^2);
        L               = sqrt(L_i^2+L_q^2);
        DLLdiscri       = 0.5 * (E-L)/(E+L);
        
        % Only update loop parameters if we're not skipping this iteration
        if ~skip_loop_update
            code_output     = code_outputLast + (tau2code/tau1code)*(DLLdiscri - DLLdiscriLast) + DLLdiscri* (0.001/tau1code);
            DLLdiscriLast   = DLLdiscri;
            code_outputLast = code_output;
            codeFreq        = signal.codeFreqBasis - code_output;
        end
        
        % PLL
        PLLdiscri           = atan(P_q/P_i) / (2*pi);
        
        % Only update loop parameters if we're not skipping this iteration
        if ~skip_loop_update
            carrier_output      = carrier_outputLast + (tau2carr/tau1carr)*(PLLdiscri - PLLdiscriLast) + PLLdiscri * (0.001/tau1carr);
            carrier_outputLast  = carrier_output;  
            PLLdiscriLast       = PLLdiscri;
            carrierFreq         = carrierFreqBasis + carrier_output;  % Modify carrier freq based on NCO command
        end
        
        % Data Record
        TckResultCT(Acquired.sv(svindex)).P_i(Index)            = P_i;
        TckResultCT(Acquired.sv(svindex)).P_q(Index)            = P_q;
        TckResultCT(Acquired.sv(svindex)).E_i(Index)            = E_i;
        TckResultCT(Acquired.sv(svindex)).E_q(Index)            = E_q;
        TckResultCT(Acquired.sv(svindex)).L_i(Index)            = L_i;
        TckResultCT(Acquired.sv(svindex)).L_q(Index)            = L_q;
        TckResultCT(Acquired.sv(svindex)).PLLdiscri(Index)      = PLLdiscri;
        TckResultCT(Acquired.sv(svindex)).DLLdiscri(Index)      = DLLdiscri;
        TckResultCT(Acquired.sv(svindex)).codedelay(Index)      = Codedelay + sum(delayValue(1:Index));
        TckResultCT(Acquired.sv(svindex)).remChip(Index)        = remChip;
        TckResultCT(Acquired.sv(svindex)).codeFreq(Index)       = codeFreq;  
        TckResultCT(Acquired.sv(svindex)).carrierFreq(Index)    = carrierFreq;  
        TckResultCT(Acquired.sv(svindex)).remPhase(Index)       = remPhase;
        TckResultCT(Acquired.sv(svindex)).remSample(Index)      = remSample;
        TckResultCT(Acquired.sv(svindex)).numSample(Index)      = numSample;
        TckResultCT(Acquired.sv(svindex)).delayValue(Index)     = delayValue(svindex,IndexSmall);
        TckResultCT(Acquired.sv(svindex)).absoluteSample(Index)  = ftell(file.fid); 
        TckResultCT(Acquired.sv(svindex)).codedelay2(Index)       = mod( TckResultCT(Acquired.sv(svindex)).absoluteSample(Index)/(file.dataPrecision*file.dataType),signal.Fs*signal.ms);
    end
    close(h);
end % end for

