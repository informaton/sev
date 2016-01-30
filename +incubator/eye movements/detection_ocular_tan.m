function detectStruct = detection_ocular_tan(source_index, optional_params)
%detect eye movements from an EOG channel based on Xin Tan et al method as
%proposed in their 2001 paper: "A simple method for computer 
%quantification of stage REM eye movement potentials"
%
%
%
% 	Majority of Spectral power for eye movements was between 0.3-2Hz
% 	Over 50% of the spectrum was between 0.3-1Hz; 
%  this study was done with 10 men, 6 women (~22 years old)
%
% updated on November 30, 2011: changed calcPSD output argument to one
% variable to correspond to change of calcPSD function.
global CHANNELS_CONTAINER;
global PSD;
% global STAGES;
% global DEFAULTS;

data = CHANNELS_CONTAINER.getData(source_index);
sample_rate = CHANNELS_CONTAINER.getSamplerate(source_index);

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        
        params.win_length_sec = 2;
        params.win_interval_sec = 2;
        params.threshold = 0.6;%the paper showed that power in the band of interest represented 65% of the total spectrum's power
%         params.REM_stage = 5;
        params.merge_within_sec = 0.1;
        plist.saveXMLPlist(pfile,params);        
    end
end

win_length_sec = params.win_length_sec;
win_interval_sec = params.win_interval_sec;

% REM_stage = params.REM_stage;
% 
% REM_epochs = find(STAGES.line == REM_stage);
% 
% 
% samplesPerEpoch = DEFAULTS.standard_epoch_sec*sample_rate;
% REM_indices = repmat(1:samplesPerEpoch,numel(REM_epochs),1);
% 
% REM_start_indices = (REM_epochs-1)*samplesPerEpoch; %should be a row vector
% 
% REM_indices = REM_indices + repmat(REM_start_indices,1,size(REM_indices,2));
% REM_indices = REM_indices'; %transpose for the following step
% REM_indices = REM_indices(:); %make it a single, sorted vector
% 
% rem_data = data(REM_indices);


%calculate the power in the bands of interest and compare to threshold
PSD_settings.removemean = PSD.removemean;
PSD_settings.interval = win_interval_sec;
PSD_settings.FFT_window_sec=win_length_sec;
PSD_settings.wintype = PSD.wintype;

[psd_all psd_x psd_nfft] = calcPSD(data,sample_rate,PSD_settings);

% [psd_all psd_x psd_nfft] = calcPSD(data,win_length_sec,win_interval_sec,channel_obj.sample_rate,PSD.wintype,PSD.removemean);

sum_all = sum(psd_all(:,psd_x>0),2); %should be a row vector
sum_band_of_interest = sum(psd_all(:,(psd_x>0 & psd_x<=2)),2);


%find the periodograms that broke the threshold
detection_indices = find((sum_band_of_interest./sum_all)>params.threshold); %will give a row vector of indices that need to be converted to the original location in the raw data

%convert these periodograms to the location in the the data of interest by
%converting the indices to samples using the window interval and the
%sample rate
periodogram_start_indices = (detection_indices-1)*sample_rate*win_interval_sec+1;

%obtain the starting indices in terms of the entire study using the
%rem_indices vector
% starts = REM_indices(periodogram_start_indices);
starts = periodogram_start_indices;
stops = starts-1+win_length_sec*sample_rate;  %or ..detectStruct.detectStruct.new_data(:)*event_length;

detectStruct.new_events = [starts(:),stops(:)];

detectStruct.new_data = data;
detectStruct.paramStruct = [];


end