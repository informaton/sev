function [stsamp QRS] = detQRS(fekg,params)
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
sl = 4*params.samplerate;
stsamp = 4*params.samplerate+1;

vsl = ceil(params.samplerate/10);
vvsl = ceil(vsl/2.5);

while stsamp < L-(4*params.samplerate-1)
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
            if sum(QRS(w4(QRSfinal,1)-round(params.samplerate*0.36):...
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
                            if sum(QRS(w4_2(QRSfinal,1)-...
                                    (params.samplerate*0.36):...
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

