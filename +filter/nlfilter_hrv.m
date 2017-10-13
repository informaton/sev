function filtSig = nlfilter_hrv(sigData, params)

    defaultParams.upperThreshold = 1.2;
    defaultParams.lowerThreshold = 0.8;
    
    % return default parameters if no input arguments are provided.
    if(nargin==0)
        filtSig = defaultParams;
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
        params.HRV.ThrUp = params.upperThreshold;
        params.HRV.ThrLo = params.lowerThreshold;
        
        params.EPOCH_LENGTH_SEC = 30;
        params.Fs = params.samplerate;
        qrs = detect_QRS(sigData,params);
        [HRV, RRstruct] = QRS2HRV(qrs, params);
        filtSig = HRV;
    end
    
end


function QRS = detect_QRS(ECG, params)
    % DETECT_QRS - Detects the QRS-complexes of a long ECG signal. It does so
    % by segmenting the data in 'e_length' second segments and passing them to DETQRS.
    %
    % QRS = detect_QRS(ECG,Fs), where ECG is the ECG signal and Fs is
    % the sampling frequency of the ECG signal. QRS is a vector of zeros,
    % with a single sample of value one where QRS complexes are detected
    % (in the peak of the R-wave).
    
    % Written by: Emil G.S. Munk, as part of the master thesis project:
    % "Automatic Classification of Obstructive Sleep Apnea".
    
    %%
    
    % Filtering signal
    ECG = ECG_filter(ECG,params.Fs);
    
    %% Initiating loop.
    L = length(ECG);
    epoch_L = params.EPOCH_LENGTH_SEC*params.Fs;
    QRS = zeros(L,1);
    
    % Setting the length behind the window = 4 sec
    % (needed for adaptive thresholding).
    sl = 4*params.Fs;
    % 'done' keeps track of how much of the signal has already been analysed.
    done = 4*params.Fs+1;
    
    while done < L-epoch_L
        % Passing signal segment to DETQRS.
        [stsamp,QRS_epoch] = detQRS(ECG(done-sl:done+epoch_L-1), params);
        % Cutting QRS as none can be detected in the first 'sl' samples.
        QRS_cut = QRS_epoch(sl+1:stsamp-1);
        % Saving result in the full QRS vector.
        QRS(done:done+length(QRS_cut)-1) = QRS_cut;
        % Saving the index of the last analysed sample.
        done = done+stsamp-sl;
    end
end

function ECG_sig = ECG_filter(ECG,Fs)
% ECG_FILTER - Filters ECG signal according to Arzeno et al. 2008, using a
% kaiser window filter with passband 10-25 Hz and 4 Hz transition bands. 
%
% ECG_sig = ECG_filter(ECG,Fs), where ECG is the ECG signal, and Fs is the
% sampling frequency. ECG_sig is the filtered signal.

% Written by: Emil G.S. Munk, as part of the master thesis project:
% "Automatic Classification of Obstructive Sleep Apnea".

[n,Wn,bta,filtype] = kaiserord(...
    [6 10 25 29],[0 1 0],[0.001 0.057501127785 0.001],Fs);
b = fir1(n, Wn, filtype, kaiser(n+1,bta), 'noscale');
ECG_sig = filtfilt(b,1,ECG);

end

function [stsamp, QRS] = detQRS(fekg, params)
    % DETQRS - Detects QRS-complexes in an ECG signal, using an algorithm first
    % described by Hamilton and Thompkins in 1986 and further developed by
    % Arzeno et al. in 2008.
    %
    % The filtered ECG is differentiated, squared and then evaluated using a
    % varying, patient inspecific threshold.
    %
    % [stsamp QRS] = detQRS(fekg,Fs), where fekg is the filtered ECG
    % signal and Fs is the sampling frequency of said ECG. stsamp is the index
    % of the last detected QRS-complex (the peak of the R-wave) used for the
    % algorithm detect_QRS. QRS is a vector of zeros where no QRS-complexes
    % are detected and the value 1 at the peak of each detected R-wave.
    
    % Written by: Emil G.S. Munk, as part of the master thesis project:
    % "Automatic Classification of Obstructive Sleep Apnea".
    
    %% Initializing.
    
    %% Transforming signal.
    % Lengthening to avoid sample loss, and then differentiating.
    fekg_long = [fekg(1);fekg(1);fekg;fekg(end);fekg(end)];
    dekg = 1/8*(2*fekg_long(5:end)+fekg_long(4:end-1)-fekg_long(2:end-3)...
        -2*fekg_long(1:end-4));
    
    % Defining sample numbers (indices).
    L = length(fekg);
    Sn = (1:L)';
    EKG = [Sn fekg];
    % Squaring signal.
    trans = [Sn dekg.^2];
    
    
    %% Initiating loop.
    QRStemp = zeros(L,1);
    QRS = zeros(L,1);
    RR_fract = 0;
    % Start 4 seconds into the signal as the first 4 seconds are from previous
    % signal segment.
    sl = 4*params.Fs;
    stsamp = 4*params.Fs+1;
    
    vsl = ceil(params.Fs/10);
    vvsl = ceil(vsl/2.5);
    
    while stsamp < L-(4*params.Fs-1)
        % Extracting windows.
        w1 = trans(stsamp-sl:stsamp-1,:);
        w2 = trans(stsamp:stsamp+sl-1,:);
        
        %% Determining threshold.
        rmsw2 = sqrt(sum(w2(:,2).^2)/length(w2(:,2)));
        
        % Finding max of epochs.
        max1 = max(abs(w1(:,2)));
        max2 = max(abs(w2(:,2)));
        
        % Comparing RMS and max values.
        if rmsw2>0.18*max2&&max2<=2*max1
            Thr = 0.39*max2;
        elseif rmsw2>0.18*max2&&max2>2*max1
            Thr = 0.39*max1;
        elseif rmsw2<=0.18*max2
            Thr = 1.6*rmsw2;
        end
        
        % Finding threshold crossings.
        cr = find(w2(:,2)>Thr);
        
        % Working on each crossing in turn.
        for n = 1:length(cr)
            
            % Searching for local max in transformed signal.
            if w2(cr(n),1)+vsl>L
                w3 = trans(w2(cr(n),1)-vsl:end,:);
            else
                w3 = trans(w2(cr(n),1)-vsl:w2(cr(n),1)+vsl,:);
            end
            [~,QRSsingle] = max(abs(w3(:,2)));
            
            if QRStemp(w3(QRSsingle,1))~=1
                QRStemp(w3(QRSsingle,1)) = 1;
                
                % Searching for max in filtered ECG.
                if w3(QRSsingle,1)+vvsl>L
                    w4 = EKG(w3(QRSsingle,1)-vvsl:end,:);
                else
                    w4 = EKG(w3(QRSsingle,1)-vvsl:w3(QRSsingle,1)+vvsl,:);
                end
                % Abs just added to avoid vulnarability to inverted ECG
                [~,QRSfinal] = max(abs(w4(:,2)));
                % Validate that no QRS is detected within the last 360 ms of
                % the signal.
                if sum(QRS(w4(QRSfinal,1)-round(params.Fs*0.36):...
                        w4(QRSfinal,1))) == 0
                    QRS(w4(QRSfinal,1)) = 1;
                end
                
                % Calculating RR-interval.
                RR = find(QRS==1,3,'last');
                if length(RR)>2
                    RR_fract = (RR(3)-RR(2))/(RR(2)-RR(1));
                end
                
                % Searching with lower threshold (0.5*Thr) if RR-interval
                % exceeds 1.5 times last RR-interval.
                if RR_fract>1.5
                    w2_2 = trans(RR(2):RR(3),:);
                    cr_2 = find(w2_2(:,2)>0.5*Thr);
                    
                    % Working on each crossing in turn.
                    if isempty(cr_2)~=1
                        for n_2 = 1:length(cr_2)
                            % Searching for local max in transformed signal.
                            if w2_2(cr_2(n_2),1)+vsl>L
                                w3_2 = trans(w2_2(cr_2(n_2),1)-vsl:end,:);
                            else
                                w3_2 = trans(w2_2(cr_2(n_2),1)-vsl:...
                                    w2_2(cr_2(n_2),1)+vsl,:);
                            end
                            [~,QRSsingle] = max(abs(w3_2(:,2)));
                            
                            if QRStemp(w3_2(QRSsingle,1))~=1
                                QRStemp(w3_2(QRSsingle,1)) = 1;
                                
                                % Searching for max in filtered ECG.
                                if w3_2(QRSsingle,1)+vvsl>L
                                    w4_2 = EKG(w3_2(QRSsingle,1)-vvsl:end,:);
                                else
                                    w4_2 = EKG(w3_2(QRSsingle,1)-vvsl:...
                                        w3_2(QRSsingle,1)+vvsl,:);
                                end
                                % Abs just added to avoid vulnarability to inverted ECG
                                [~,QRSfinal] = max(abs(w4_2(:,2)));
                                % Validating that no QRS is detected within
                                % the last 360 ms of the signal.
                                if sum(QRS(w4_2(QRSfinal,1)-(params.Fs*0.36):...
                                        w4_2(QRSfinal,1))) == 0;
                                    QRS(w4_2(QRSfinal,1)) = 1;
                                end
                            end
                        end
                    end
                end
            end
        end
        % Saving index of last analyzed sample and forcing the loop to continue
        % 'sl' samples later if no QRS-complexes are detected (searchback at
        % long RR-intervals will find the missed QRS-complexes later).
        stsamp_new = find(QRS==1,1,'last')+1;
        if stsamp_new<sl+1
            stsamp_new = sl+1;
        end
        if stsamp_new==stsamp
            stsamp = stsamp+sl;
        elseif stsamp_new<stsamp
            stsamp = stsamp+sl;
        elseif isempty(stsamp_new)
            stsamp = stsamp+sl;
        else
            stsamp=stsamp_new;
        end
    end
    
end

function [HRV,RRstruct] = QRS2HRV(sleepQRS, params)
    % QRS2HRV transforms the QRS-signal from detect_QRS to a heart rate
    % variability (HRV) signal - in essence the instantaneous heart rate.
    % This is done by calculating the heart rate between each detected QRS and
    % interpolating through cubic spline.
    %
    % HRV = QRS2HRV(sleepQRS,Fs), where sleepQRS is a vector of
    % zeros and ones, Fs is the sampling frequency of the QRS signal.
    % HRV is a signal of values that correspond to the heart rate at that time
    % instance, in beats per minute.
    %
    % If the QRS signal comes from detect_QRS, remember to remove first part of
    % the signal where no QRS complexes are detected to avoid divergence in HRV
    % signal.
    
    % Written by: Emil G.S. Munk, as part of the master thesis project:
    % "Automatic Classification of Obstructive Sleep Apnea".
    
    %%
    
    
    %% Initializing and calculating RR intervals.
    R = find(sleepQRS==1);
    RR = R(2:end)-R(1:end-1);
    
    %% Finding Thresholds for artifact removal.
    Thr_up = zeros(size(RR));
    Thr_lo = zeros(size(RR));
    
    % Dividing signal in 5 beat segments.
    segments = floor(length(RR)/5);
    for s = 1:segments
        Thr_up((s-1)*5+1:s*5) = params.HRV.ThrUp*median(RR((s-1)*5+1:s*5));
        Thr_lo((s-1)*5+1:s*5) = params.HRV.ThrLo*median(RR((s-1)*5+1:s*5));
    end
    
    if floor(length(RR)/5)~=ceil(length(RR)/5)
        Thr_up(segments*5+1:end) = params.HRV.ThrUp*median(RR(segments*5+1:end));
        Thr_lo(segments*5+1:end) = params.HRV.ThrLo*median(RR(segments*5+1:end));
    end
    
    %% Removing artefacts while calculating heart rate.
    RRstruct.RRtime = R(2:end);
    RRstruct.RRdur = RR;
    RRstruct.flagged_RR = zeros(length(RR),1);
    for n = 1:length(RR)
        % Checking if RR interval is withing thresholds.
        if ~(RR(n)<Thr_up(n)&&(params.samplerate/RR(n))*60<150&&RR(n)>Thr_lo(n)...
                &&(params.samplerate/RR(n))*60>35==1)
            RRstruct.flagged_RR(n) = 1;
        end
    end
    
    pulse = (params.samplerate./RRstruct.RRdur(RRstruct.flagged_RR==0)).*60;
    
    % This results in a sampling frequency of 1 for HRV
    % samp_line=1:params.samplerate:length(sleepQRS);
    
    samp_line = 1:numel(sleepQRS);
    %% Creating HRV signal through cubic spline.
    HRV = spline(RRstruct.RRtime(RRstruct.flagged_RR==0),[0;pulse;0],samp_line)';
    
end

