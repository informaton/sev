function detectStruct = detection_DB_EEG_PLM_measures(data,optional_params, stageStruct)
%determine EEG changes surrounding PLM detections found in surrounding the 
% PLM events (or any event really) indicated by the detector ID parameter.
%detector however, it does not have to be leg movements).
%Author: Hyatt Moore IV
%Created: 5.1.2013

%this function's flow is as follows:
% 1. gather data
% 2. obtain study identifiers
% 3. obtain database events
% 4. calculate PSD before and after each event's onset and following each
% offset
% 5. store frequency band differences between offsets and onsets and store as parameters for new events
% taken as the post event range for PSD calculation.


% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(optional_params))
    params = optional_params;
else
    mfile = mfilename('fullpath');
    pfile = strcat(mfile,'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.detectorID = 143; %the detector ID of the events to load in the database
        params.window_size_sec = 3; %how large of a window to calculate the PSD over.
        plist.saveXMLPlist(pfile,params);
    end
end

window_size = params.window_size_sec*params.samplerate;

%PSD parameters
PSD_params.FFT_window_sec = params.window_size_sec;
PSD_params.interval = params.window_size_sec;
PSD_params.wintype = 'hamming';
PSD_params.removemean = 1;

if(mym==1)
    openWSC(); %open the Wisconsin Database
end


% 2. obtain study identifiers
[folder, patstudy, extension] = fileparts(stageStruct.filename);
[PatID,StudyNum] = CLASS_events_container.getDB_PatientIdentifiers(patstudy);
q = mym('select patstudykey from studyinfo_t where patid="{S}" and studynum={Si}',PatID,StudyNum);
key = q.patstudykey;

% 3. obtain database events
q = mym(sprintf('select start_sample, stop_sample from events_t where detectorid=%u and patstudykey=%u',params.detectorID,key));
Evts = [q.start_sample,q.stop_sample];


%ensure we stay within the boundaries of the data vector
toolong = Evts(:,2)+window_size>=stageStruct.study_duration_in_seconds*params.samplerate;
tooshort = Evts(:,1)-window_size<=1;
Evts = Evts(~toolong&~tooshort,:);
    
numEvents = numel(Evts(:,1));

if(numEvents>0)
    if(~issorted(Evts(:,1)))
        [~,sort_i]=sort(Evts(:,1));
        Evts = Evts(sort_i,:);
    end
    
    % 4. calculate PSD before and after each event's onset and following each
    % offset
    onset_ROI = [q.start_sample-window_size,q.start_sample]-1;
    
    %use this if I want to show immediately following the PLM
    offset_ROI = [q.stop_sample, q.stop_sample+window_size]+1;

    offset_ROI = [q.start_sample, q.start_sample+window_size]+1;
    new_events = offset_ROI;
    
                
    nfft = PSD_params.FFT_window_sec*params.samplerate;
    num_freq_bins = ceil((nfft+1)/2);
    
    power_beforeOnset = zeros(numEvents,num_freq_bins);
    power_afterOffset = zeros(numEvents,num_freq_bins);

    for r=1:numEvents
        [power_beforeOnset(r,:), ~, ~] = calcPSD(data(onset_ROI(r,:)),params.samplerate,PSD_params);
        [power_afterOffset(r,:),freqs,~] = calcPSD(data(offset_ROI(r,:)),params.samplerate,PSD_params);
    end
    
    % 5. store frequency band differences between offsets and onsets and store as parameters for new events
    % taken as the post event range for PSD calculation.
    power_diff = power_afterOffset-power_beforeOnset;
    
    
%     paramStruct.slow2 = sum(power_afterOffset(:,slow_freqs),2) - sum(power_beforeOnset(:,slow_freqs),2); %mean across the rows to produce a column vector
%       
%     paramStruct.slow3 = mean(power_diff(:,freqs>0&freqs<4),2); %mean across the rows to produce a column vector

%     paramStruct.slow = sum(power_diff(:,freqs>0&freqs<4),2)*10^6; %mean across the rows to produce a column vector
%     paramStruct.delta = sum(power_diff(:,freqs>=0.5&freqs<4),2)*10^6; %mean across the rows to produce a column vector
%     paramStruct.theta = sum(power_diff(:,freqs>=4&freqs<8),2)*10^6;
%     paramStruct.alpha = sum(power_diff(:,freqs>=8&freqs<12),2)*10^6;
%     paramStruct.sigma = sum(power_diff(:,freqs>=12&freqs<16),2)*10^6;
%     paramStruct.beta  = sum(power_diff(:,freqs>=16&freqs<30),2)*10^6;
%     paramStruct.gamma = sum(power_diff(:,freqs>=30),2)*10^6;

    paramStruct.slow = sum(power_diff(:,freqs>0&freqs<4),2)*params.samplerate; %mean across the rows to produce a column vector
    paramStruct.delta = sum(power_diff(:,freqs>=0.5&freqs<4),2)*params.samplerate; %mean across the rows to produce a column vector
    paramStruct.theta = sum(power_diff(:,freqs>=4&freqs<8),2)*params.samplerate;
    paramStruct.alpha = sum(power_diff(:,freqs>=8&freqs<12),2)*params.samplerate;
    paramStruct.sigma = sum(power_diff(:,freqs>=12&freqs<16),2)*params.samplerate;
    paramStruct.beta  = sum(power_diff(:,freqs>=16&freqs<30),2)*params.samplerate;
    paramStruct.gamma = sum(power_diff(:,freqs>=30),2)*params.samplerate;
%     slow_freqs = freqs>0&freqs<4;
%     delta_freqs = freqs>=0.5&freqs<4;
%     theta_freqs = freqs>=4&freqs<8;
%     alpha_freqs = freqs>=8&freqs<12;
%     sigma_freqs = freqs>=12&freqs<16;
%     beta_freqs = freqs>=16&freqs<30;
%     gamma_freqs = freqs>=30;

else    
    new_events = [];
    paramStruct = [];
end
        
detectStruct.new_events = new_events;
detectStruct.new_data = data;
detectStruct.paramStruct = paramStruct;