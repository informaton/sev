%> @file detection_breathing.m
%> @brief % This function detects the sample number of each individual breath (max
%> and min nasal pressure amplitude. Further, is the inspiration/expiration
%> inflection points estimated. Rib and abdomen belts are used to define
%> breathing frequency and findpeak search used to estimate the max/min in
%> nasal pressure. The start of each inspiration is defined by the "knee" in
%> nasal pressure and the knee height is used to find the start of the
%> expiration.
% =========================================================================
%> @param Cell of signal data vectors, which include
%> @li @c PRES: nasal pressure signal (not filtered)
%> @li @c RIB: rib belt signal (bandpass filtered 0.5-5 Hz)
%> @li @c ABDOM: abdomen belt signal (bandpass filtered 0.5-5 Hz)
%> @param params A structure for variable parameters passed in
%> with following fields [ = default value]
%> @li @c window_dur_min [= 2] % Moving window duration = 2 minutes
%> @li @c window_overlap [= 0.5]; % Overlap moving window (0.5 = 50% overlap)
%> @li @c peak_inter_sec [= 1.4]; % seconds between peaks, used to be 1.25
%> @li @c samplerate
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data  Same as input signal (srcSig)
%> @li @c .new_events A two column matrix of start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c .paramStruct Empty value returned (i.e. []).
%> @note Written by Henriette Koch, nov. 2013.
%  Added to SEV 8/22/2014, Hyatt Moore IV
function detectStruct = detection_breathing(srcSigCell,params,stageStruct)

% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.window_dur_min = 5; % Moving window duration  in minutes
defaultParams.window_overlap = 0.5; % Overlap moving window (0.5 = 50% overlap)
defaultParams.peak_inter_sec = 1.4; % sec. between peaks, used to be 1.25

% return default parameters if no input arguments are provided.
if(nargin==0)
    detectStruct = defaultParams;
else
    
    if(nargin<2 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future            
            params = defaultParams;
            plist.saveXMLPlist(pfile,params);
        end
    end
    
    
    
    %% Initial settings
    PRES = srcSigCell{1};
    RIB = srcSigCell{2};
    ABDOM = srcSigCell{3};
    
    Fs = params.samplerate;
    peak_inter_sec = params.peak_inter_sec; % sec. between peaks, used to be 1.25
    % num_ep = 10; % mov. window duration [1 epoch = 30 sec.], 10 = 5 minutes
    ws = floor(Fs*params.window_dur_min*60);% window size in samples
    olap = params.window_overlap; % overlap, moving window
    lbw = floor(olap*ws); % length between windows
    sigw = floor(size(PRES,1)/lbw); % number of windows
    avg_breath_duration_sec = 3; % short/average duration of breath [sec.] => 20 breaths/min [used to be... 4; % average/long breath [sec.] => 15 breaths/min]
    
    % LOOP moving window
    % pres_amplitude = [];
    % Fpres_minidx=[];
    % Fpres_amp=[];
    Fpres_maxidx=[];
    beltshift=[];
    % n=1;
    
    for e = 1:sigw-1
        % ribbelt=[];
        % abdomenbelt=[];
        % pres_minidx=[];
        % pres_minidx=[];
        % gr_am=[];
        % mth_del=[];
        % event_th=[];
        % e_stop=[];
        % e_start=[];
        % base=[];
        
        st = (e-1)*lbw+1; % window start
        w = st:st+ws-1; % define window
        
        
        % Go through nasal pressure signal using 5 minute windows with 1 minute
        % step size. If 90% of the window is excluded (NaN) => exclude window.
        if sum(isnan(PRES(w)))/ws > 0.9
            continue
        end
        
        
        %% Original signal in period
        % Normalize signals
        pressure = PRES(w)./nanstd(PRES(w))-nanmedian(PRES(w)./nanstd(PRES(w)));
        ribbelt = RIB(w)./std(RIB(w))-median(RIB(w)./std(RIB(w))); % lowpass filtered, changes 2 May
        abdomenbelt = ABDOM(w)./std(ABDOM(w))-median(ABDOM(w)./std(ABDOM(w))); % lowpass filtered, changes 2 May
        
        
        %% Delay adjusted
        % Belts are shifted to align with pressure
        [cbr, lagsbr] = xcorr(pressure,ribbelt);
        [cba, lagsba] = xcorr(pressure,abdomenbelt);
        [valcbr idxcbr] = max(cbr); [valcba idxcba] = max(cba);
        tdelaybr = ceil(lagsbr(idxcbr)); tdelayba = ceil(lagsba(idxcba));
        
        % Calculate breathing frequency
        nfft = 4*2^nextpow2(size(pressure,1));
        f = (Fs/2*linspace(0,1,nfft/2+1))';
        for n = 1:3
            if n == 1
                sig = pressure;
            elseif n == 2
                sig = ribbelt;
            elseif n == 3
                sig = abdomenbelt;
            end
            
            fp = abs(fft(sig,nfft)).^2/size(sig,1)/Fs; % periodogram
            fp = fp(1:nfft/2+1);        % one-sided power spectrum
            [valmax idxmax] = max(fp);
            Freq(n) = f(idxmax);
        end
        maxFreq = median(Freq); % phase is median of most present frequency
        
        % Ensure signal is moved right way (pressure is always delayed compared to belts => belts are delayed)
        if tdelaybr < 0 && tdelaybr-floor((1/maxFreq)*Fs)>0
            tdelaybr = tdelaybr-floor((1/maxFreq)*Fs); % samples ribbelt is moved
        end
        beltshift = [beltshift tdelaybr]; % save "beltshift" to adjust belt for calculating belt amplitudes correctly
        
        % Align belts to nasal pressure
        ribbelt(size(ribbelt,1)-tdelaybr-1:size(ribbelt,1))=[];
        abdomenbelt(size(abdomenbelt,1)-tdelaybr-1:size(abdomenbelt,1))=[];
        ribbelt = [repmat(NaN,tdelaybr,1); ribbelt]; % belts are moved according to chest due to paradoxial breathing, therefore abdomen is moved to chest
        abdomenbelt = [repmat(NaN,tdelaybr,1); abdomenbelt];
        
        % Check if breathing frequency in the ribbelt is within normal ragne (ribbelt="Freq(2)"). If not, the breathing frequency is hardcoded to "ceil(1/Freq(2))"
        % Calculate duration of one breath (sec.).
        if Freq(2) > 1 || Freq(2) < 0.2 % if rib frequency is more than 1 Hz or less than 0.2 Hz (60 breaths/min and less than 12 breaths/min)
            ribphase = avg_breath_duration_sec; % average/long duration of breath (in sec.)
        else ribphase = ceil(1/Freq(2));
        end
        
        % Save rib phase for evaluation
        rp(e,1) = Freq(2);
        rp(e,2) = ribphase;
        
        
        %% Derive max in nasal pressure
        % Calculate max and min index for each breath using "nasalpresmax.m"
        [pres_maxidx] = nasalpresmax(pressure,ribbelt,abdomenbelt,ribphase,peak_inter_sec,Fs);
        
        % Save each loop run in same vector
        Fpres_maxidx = [Fpres_maxidx ; pres_maxidx'+st];
        
        
    end % end window loop
    fpres_maxidx = sort(unique(Fpres_maxidx),'ascend');
    
    % Remove close max peaks
    ac = [fpres_maxidx;NaN]-[NaN;fpres_maxidx];
    acidx = find(abs(ac)<peak_inter_sec*Fs);
    fpres_maxidx(acidx)=[];
    
    
    %% Derive min in nasal pressure
    % Estimate min in nasal pressure, defined as minimum between two max peaks
    fpres_minidx = zeros(size(fpres_maxidx,1)-1,1);
    for i = 1:size(fpres_maxidx,1)-1
        [pres_minval pres_minlocs] = min(PRES(fpres_maxidx(i):fpres_maxidx(i+1)));
        fpres_minidx(i) = fpres_maxidx(i)+pres_minlocs-1;
    end
    
    if(~isempty(fpres_maxidx))
        fpres_maxidx(1)=[];
    end
    
    
    %% Check if nasal pressure is flipped
    % Use amplitude values to determine if nasal pressure is flipped. Use ratio
    % between max and min values.
    po = abs(PRES(fpres_maxidx(1:end)));
    ne = abs(PRES(fpres_minidx(1:end)));
    po_ne = nanmedian(po./ne); % "true direction of signal" contains larger negative values (in WSC due to device filtering, short time constant)
    if po_ne >=1 % nasal pressure is flipped
        pressureflip = -1;
        Imin = fpres_maxidx(1:end-1);
        Imax = fpres_minidx(2:end);
    else pressureflip = 1;
        Imin = fpres_minidx;
        Imax = fpres_maxidx;
    end
    
    
    %% OUTPUT for min/max index in each breath
    % Remove first and last index due to amplitude calculation
    pressure_event = [Imin(1:end-2) Imax(1:end-2)]; % breath start/stop (min/max nasal pressure)
    % If start/stop same sample number, delete
    pressure_event(pressure_event(:,2)-pressure_event(:,1)==0,:)=[];
    
    
    
    % %% Estimate start of inspiration and expiration
    % % Determine start of inspiration and expiration. Use pressure interval with
    % % most samples (= knee) to define the start inspiration. Tend to be two
    % % bumps in the knee, according to Oscar the middle bump is the most precise
    % % for "knee detection".
    % tiny = 3; % look tiny after to ensure unstable signal is not causing wrong detection
    % for i = 1:size(pressure_event,1)-1
    %
    %     % Use percentile of np samples to determine knee.
    %     [pre_midpb pre_p40 pre_p60] = pop_quantile(pressureflip*PRES(pressure_event(i,1):pressure_event(i,2)),0.3,0.6,20);
    %
    %     % Only derive insp/exp if non-NaN
    %     if ~isnan(pre_midpb)
    %         insp_start1 = pressure_event(i,1)+find(pressureflip*PRES(pressure_event(i,1):pressure_event(i,2)) ...
    %             >= pre_midpb,1,'first'); % look 10 percent lower than median to ensure search if wide enough
    %
    %         if insp_start1+tiny < pressure_event(i,2)
    %             % Zero crossing for median (standard clean example)
    %             [idx_zero idx_up idx_down] = zerocrossing(pressureflip*PRES(insp_start1+tiny:pressure_event(i,2))-pressureflip*PRES(insp_start1));
    %             % Look 10 percent lower than median to ensure search if wide enough for minimum detection
    %             insp_start1_te = pressure_event(i,1)+find(pressureflip*PRES(pressure_event(i,1):pressure_event(i,2)) ...
    %                 >= pre_midpb-0.5*pressureflip*PRES(pressure_event(i,2)),1,'first');
    %             te = find(diff(pressureflip*PRES(insp_start1_te+tiny:pressure_event(i,2)))==0);
    %
    %             if ~isempty(te)
    %                 [teval tempminidx] = min(pressureflip*PRES(insp_start1+tiny+te-1));
    %             else tempminidx = [];
    %             end
    %
    %         else idx_down = []; tempminidx = [];
    %         end
    %
    %         % Three ways to set start inspiration sample number
    %         if isempty(idx_down) && isempty(tempminidx)
    %             insp_start(i) = pressure_event(i,1)+floor((pressure_event(i,2)-pressure_event(i,1))/2);
    %         elseif isempty(idx_down)
    %             insp_start(i) = insp_start1+tiny+tempminidx(1);
    %         else insp_start(i) = insp_start1+idx_down(1)-1; % select first idx_down
    %         end
    %
    %         % If start inspiration is set close to min pressure or max pressure, move inspiration/expiration to half way between min/max pressure
    %         if (pressureflip*PRES(pressure_event(i,1))+(pressureflip*PRES(insp_start(i))))/abs(pressure_event(i,1)-pressure_event(i,2)) < -0.8 || ...
    %                 (pressureflip*PRES(pressure_event(i,2))-(pressureflip*PRES(insp_start(i))))/pressureflip*PRES(pressure_event(i,2)) > 0.9
    %             insp_start(i) = pressure_event(i,1)+(ceil((pressure_event(i,2)-pressure_event(i,1))/1.5));
    %         end
    %
    %         % Start expiration is defined to be when the nasal pressure crosses the amplitude of the knee (to handle baseline drift)
    %         [idx_zero2 idx_up2 idx_down2] = zerocrossing(pressureflip*PRES(pressure_event(i,2):pressure_event(i+1,1))-pressureflip*PRES(insp_start(i)));
    %         if isempty(idx_down2)
    %             exp_start(i) = pressure_event(i,2)+floor((pressure_event(i+1,1)-pressure_event(i,2))/2);
    %         else
    %             exp_start(i) = pressure_event(i,2)+idx_down2(1);
    %         end
    %
    %         % If NaN (due to electrode-pop or signal values zero continue NaN
    %     else
    %         insp_start(i) = NaN;
    %         exp_start(i) = NaN;
    %     end
    % end
    
    %should i exclude the Nan's?
    % pressure_startInspExp = [insp_start' exp_start'];
    
    
    
    detectStruct.new_events = pressure_event;
    detectStruct.new_data = srcSigCell{1};
    detectStruct.paramStruct = [];
end
end

function [idx_zero idx_up idx_down] = zerocrossing(sig)
% This function calculates when a signal crosses zero and specifies the
% crossing direction.
% Written by Henriette Koch
%
% INPUT
% sig: signal
%
% OUTPUT
% idx_zero: index for all zerocrossings
% idx_up: index for negative->postive values
% idx_down: index for positive->negative values
% =========================================================================

% Find zeros crossings
t1=sig(1:end-1);
t2=sig(2:end);
tt = t1.*t2;
idx_zero = find(tt<0);

% Specify direction of crossing up/down
x = diff(sign(sig));
idx_up = find(x>0);
idx_down = find(x<0);
end

function [pres_maxidx] = nasalpresmax(pressure, ribbelt, abdomenbelt,ribphase,pth_int,Fs)
% This script calculates the index of maximum nasal pressure in each breath
% by using the rib and abdomen belts to define the area for searching the
% max nasal pressure (used to be nasalpres_amplitude)
% Written by Henriette Koch, 2014.
%
% INPUT
% Opressure: originals pressure
% pressure: normalized nasal pressure
% ribbelt: standardized rib belt
% abdomenbelt: standardized abdomen belt
% ribidx: shift between ribbelt and nasal pressure
% Fs: sampling frequency nasal pressure
%
% OUTPUT
% pres_maxidx: pressure max index in each breath
% =========================================================================


%% Breathing effort peak detection
% Find rib peaks (only positive) using phase to define minimum peak distance (0.75*phase).
th_peak = 0.75; % 0.75 is a good value
[pksrib pksrib_locs] = findpeaks(ribbelt,'minpeakdistance',ceil(th_peak*ribphase*Fs)); % rib
pksrib_locs(ribbelt(pksrib_locs)<-0.5)=[]; % delete negative values (threshold is -0.1 and not 0 due to possible baseline drift)

% Find abdomen peak in same area as rib (only positive)
% IF loop to handle start/end of window
th_abpeak = 0.25; % percentage of ribphase to look
th_look = ceil(th_abpeak*ribphase*Fs);
for i = 1:size(pksrib_locs,1)
    % If normal breathing effort
    if sum(sign(abdomenbelt(pksrib_locs))) >= 0
        if pksrib_locs(i)-th_look>0 && pksrib_locs(i)+th_look<size(abdomenbelt,1)
            [pinipksab pinipksab_locs] = max(abdomenbelt(pksrib_locs(i)-th_look:pksrib_locs(i)+th_look));
            Inipksab_locs(i) = pinipksab_locs+pksrib_locs(i)-th_look;
        elseif pksrib_locs(i)-th_look<0
            [pinipksab pinipksab_locs] = max(abdomenbelt(1:pksrib_locs(i)+th_look));
            Inipksab_locs(i) = pinipksab_locs;
        elseif pksrib_locs(i)+th_look>size(abdomenbelt,1)
            [pinipksab pinipksab_locs] = max(abdomenbelt(pksrib_locs(i)-th_look:size(abdomenbelt,1)));
            Inipksab_locs(i) = pinipksab_locs+pksrib_locs(i)-th_look;
        end
        % If paradoxial breathing effort
    elseif sum(sign(abdomenbelt(pksrib_locs))) < 0
        if pksrib_locs(i)-th_look>0 && pksrib_locs(i)+th_look<size(abdomenbelt,1)
            [pinipksab pinipksab_locs] = min(abdomenbelt(pksrib_locs(i)-th_look:pksrib_locs(i)+th_look));
            Inipksab_locs(i) = pinipksab_locs+pksrib_locs(i)-th_look;
        elseif pksrib_locs(i)-th_look<0
            [pinipksab pinipksab_locs] = min(abdomenbelt(1:pksrib_locs(i)+th_look));
            Inipksab_locs(i) = pinipksab_locs;
        elseif pksrib_locs(i)+th_look>size(abdomenbelt,1)
            [pinipksab pinipksab_locs] = min(abdomenbelt(pksrib_locs(i)-th_look:size(abdomenbelt,1)));
            Inipksab_locs(i) = pinipksab_locs+pksrib_locs(i)-th_look;
        end
    end
end
pksab_locs = Inipksab_locs';
pksab_locs(abdomenbelt(pksab_locs<0))=[];


% Check if any effort peaks are overseen
nrib = 1; nab = 1;
for i = 1:10
    [inipksrib_locs inipksab_locs] = beltrecheck(ribbelt,abdomenbelt,pksrib_locs,pksab_locs,Fs,ribphase);
    pksrib_locs = [pksrib_locs;inipksrib_locs];
    pksab_locs = [pksab_locs;inipksab_locs];
    clear inipksrib_locs; clear inipksab_locs;
    
    % Take out unique peaks
    pksrib_locs = unique(pksrib_locs);
    pksab_locs = unique(pksab_locs);
    if nrib == size(pksrib_locs,1) && nab == size(pksab_locs,1),break,end % break loop when all peaks are detected
    nrib = size(pksrib_locs,1); nab = size(pksab_locs,1); % count number of peaks
end


%% PRESSURE - max will be min (switched) if "pturn" is not correct
% Find pressure peaks using rib peaks and phase to define search area.
% MAX
th_look = 0.45; % less than 0.5*phase to ensure no double scoring
for i = 1:min([size(pksrib_locs,1) size(pksab_locs,1)])
    ra=[pksrib_locs(i) pksab_locs(i)]; % From most lesft to most right effort peak
    [aval aidx] = min(ra); [bval bidx] = max(ra);
    if aval-ceil(th_look*ribphase*Fs)>=1 && size(pressure,1)>=bval+ceil(th_look*ribphase*Fs)
        [pres_maxv pres_maxlocs] = max(pressure(aval-ceil(th_look*ribphase*Fs): ...
            bval+ceil(th_look*ribphase*Fs)));
        pres_maxidx(i) = ra(aidx)-ceil(th_look*ribphase*Fs)+pres_maxlocs-1;
    else pres_maxidx(i) = NaN;
    end
end
pres_maxidx(isnan(pres_maxidx))=[];

if size(pres_maxidx,1)>1
    % Delete close peaks
    maxdiff = [pres_maxidx NaN]-[NaN pres_maxidx];
    [th_maxdiff th_maxdiffidx] = find(maxdiff < ceil(pth_int*Fs));
    if ~isempty(th_maxdiffidx)
        for i = 1:size(th_maxdiffidx,2)
            [mthdiff mthdiffidx] = min([pressure(th_maxdiffidx(i)-1) pressure(th_maxdiffidx(i))]);
            if mthdiffidx == 1
                mth_del(i) = th_maxdiffidx(i)-1;
            else
                mth_del(i) = th_maxdiffidx(i);
            end
        end
        pres_maxidx(mth_del') = [];
    end
    pres_maxidx=sort(pres_maxidx,'ascend');
end
end

function [pksrib_locs pksab_locs] = beltrecheck(ribbelt,abdomenbelt,inipksrib_locs,inipksab_locs,Fs,ribphase)

% Check if any effort peaks are overseen
th_intlook = 0.1; % percentage of phase to look
th_look = floor(th_intlook*ribphase*Fs); n=1;
xtrapksrib_locs = []; xtrapksab_locs=[];

for i = 2:min([size(inipksrib_locs,1) size(inipksab_locs,1)])
    if inipksrib_locs(i-1)+th_look >= inipksrib_locs(i)-th_look || ...
            inipksab_locs(i-1)+th_look >= inipksab_locs(i)-th_look || ...
            numel([inipksrib_locs(i-1)+th_look:inipksrib_locs(i)-th_look])<3 || ...
            numel([inipksab_locs(i-1)+th_look:inipksab_locs(i)-th_look])<3 continue
    end
    [ri_mval Irimlocs] = findpeaks(ribbelt(inipksrib_locs(i-1)+th_look:inipksrib_locs(i)-th_look),'npeaks',2,'sortstr','descend');
    [ai_mval Iaimlocs] = findpeaks(abdomenbelt(inipksab_locs(i-1)+th_look:inipksab_locs(i)-th_look),'npeaks',2,'sortstr','descend');
    
    % Rib
    dirim = (inipksrib_locs(i)-inipksrib_locs(i-1)); % distance between peaks
    if isempty(ri_mval) || isempty(ai_mval) continue
    end
    if size(Irimlocs,1)~=1 && any(Irimlocs<dirim/4) || ... % Two interpeaks are taken out, select middle intersect
            size(Irimlocs,1)~=1 && any(Irimlocs>dirim/(3/4))
        [val idx] = min([abs(Irimlocs(1)-dirim/2) abs(Irimlocs(1)-dirim/2)]);
        rimlocs = Irimlocs(idx);
    else [val idx] = max([abs(ri_mval(1)-dirim/2) abs(ri_mval(1)-dirim/2)]);
        rimlocs = Irimlocs(idx);
    end
    
    % Abdomen
    dirim = (inipksab_locs(i)-inipksab_locs(i-1)); % distance between peaks
    if size(Iaimlocs,1)~=1 && any(Iaimlocs<dirim/4) || ... % Two interpeaks are taken out, select middle intersect
            size(Iaimlocs,1)~=1 && any(Iaimlocs>dirim/(3/4))
        [val idx] = min([abs(Iaimlocs(1)-dirim/2) abs(Iaimlocs(1)-dirim/2)]);
        aimlocs = Iaimlocs(idx);
    else [val idx] = max([abs(ai_mval(1)-dirim/2) abs(ai_mval(1)-dirim/2)]);
        aimlocs = Iaimlocs(idx);
    end
    
    % Check if inter-peak
    if ribbelt(rimlocs+inipksrib_locs(i-1)+th_look) > 0 && ...
            ribbelt(rimlocs+inipksrib_locs(i-1)+th_look) > min([ribbelt(inipksrib_locs(i-1)+th_look) ribbelt(inipksrib_locs(i)-th_look)])*0.7 && ...
            ribbelt(rimlocs+inipksrib_locs(i-1)+th_look) < max([ribbelt(inipksrib_locs(i-1)) ribbelt(inipksrib_locs(i))])*1.3 || ...
            abdomenbelt(aimlocs+inipksab_locs(i-1)+th_look) > 0 && ...
            abdomenbelt(aimlocs+inipksab_locs(i-1)+th_look) > min([abdomenbelt(inipksab_locs(i-1)+th_look) abdomenbelt(inipksab_locs(i)-th_look)])*0.7 && ...
            abdomenbelt(aimlocs+inipksab_locs(i-1)+th_look) < max([abdomenbelt(inipksab_locs(i-1)+th_look) abdomenbelt(inipksab_locs(i)-th_look)])*1.3
        xtrapksrib_locs(n) = rimlocs+inipksrib_locs(i-1)+th_look;
        xtrapksab_locs(n) = aimlocs+inipksab_locs(i-1)+th_look;
        n = n+1;
    end
end

pksrib_locs = sort([inipksrib_locs;unique(xtrapksrib_locs)'],'ascend');
pksab_locs = sort([inipksab_locs;unique(xtrapksab_locs)'],'ascend');
end

function [sig_perout p_low p_up] = pop_quantile(sig,p_low,p_up,sm)
% This function finds the most popular samples within two percentile
% boundaries and used to derive the start the inspiration by estimating the
%"knee" in nasal pressure.
% Written by Henriette Koch, 2014.
%
% INPUT
% sig = signal
% p_low = lower percentile threshold
% p_up = upper percentile threshold
% sm = number of intervals the signal is split into when evaluated
%
% OUTPUT
% perout = most common samples within percentile
% per_low = lower percentile value
% per_up = upper percentile value
% =========================================================================

% Max/min in signal
map = max(sig); mip = min(sig);
if sum(isnan(sig)) > 0.8*size(sig,1) % if more than 80% is NaN, not breath
    sig_perout = NaN; p_low = NaN; p_up = NaN;
elseif map==0 && mip==0
    sig_perout = NaN; p_low = NaN; p_up = NaN;
elseif map == mip
    sig_perout = NaN; p_low = NaN; p_up = NaN;
else
    
    % Quantiles
    p_low = quantile(sig,p_low);
    p_up = quantile(sig,p_up);
    
    % Find pressure interval with most samples (= knee in inspiration)
    stp = map-mip;
    pv = [mip:stp/sm:map];
    for s = 1:sm-1
        presv(s) = numel(sig(sig(:) > pv(s) & sig(:) < pv(s+1)));
    end
    [valpresv idxpresv] = max(presv);
    bpv = [pv(idxpresv) pv(idxpresv+1)];
    
    sig_perout = bpv(1)+0.5*(bpv(2)-bpv(1));
    
end
end