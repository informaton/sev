%> @file
%> @brief Eye movement detector based on based on Xin Tan et al method as
%> proposed in their 2001 paper: "A simple method for computer 
%> quantification of stage REM eye movement potentials"
%======================================================================
%> @brief Detect eye movements from an EOG channel based on Xin Tan et al method as
%> proposed in their 2001 paper: "A simple method for computer 
%> quantification of stage REM eye movement potentials"
%> @note Majority of Spectral power for eye movements was between 0.3-2Hz
%> Over 50% of the spectrum was between 0.3-1Hz; 
%> this study was done with 10 men, 6 women (~22 years old)
%
%> @param data Sampled EOG signal as a column vector.  
%> @param params A structure for variable parameters passed in
%> with following fields  {default}
%> @li @c params.win_length_sec Window length in seconds to calculate power over {2}
%> @li @c params.win_interval_sec Separation in seconds between consecutive power calculations {2}
%> @li @c params.threshold  Percent of power the band of interest must exceed {0.6} 
%> @note %the paper Paper showed that power in the band of interest
%> represented 65% of the total spectrum's power.
%> @li @c params.merge_within_sec  Duration to merge consecutive events within {0.1}
%
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Duplicate of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Structure with following field(s) which are vectors
%> with the same numer of elements as rows of @c new_events.
%> @li @c paramStruct.pct_of_power The percent of power represented by the band of interest.
function detectStruct = detection_ocular_tan(data,params, stageStruct)
%
% updated on November 30, 2011: changed calcPSD output argument to one
% variable to correspond to change of calcPSD function.

%% implementation by Hyatt Moore IV
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input

% global PSD;

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))
    
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

samplerate = params.samplerate;

win_length_sec = params.win_length_sec;
win_interval_sec = params.win_interval_sec;

params.low_freq = 0.3;
params.high_freq = 1.0;
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

wintype = 'hann';
removemean = 1;
%calculate the power in the bands of interest and compare to threshold
PSD_settings.removemean = removemean;
PSD_settings.interval = win_interval_sec;
PSD_settings.FFT_window_sec=win_length_sec;
PSD_settings.wintype = wintype;

[psd_all psd_x psd_nfft] = calcPSD(data,samplerate,PSD_settings);

% [psd_all psd_x psd_nfft] = calcPSD(data,win_length_sec,win_interval_sec,channel_obj.sample_rate,PSD.wintype,PSD.removemean);

sum_all = sum(psd_all(:,psd_x>0),2); %should be a row vector
sum_band_of_interest = sum(psd_all(:,(psd_x>=params.low_freq & psd_x<=params.high_freq)),2);


%find the periodograms that broke the threshold
paramStruct.pct_of_power = (sum_band_of_interest./sum_all);
detection_indices = find(paramStruct.pct_of_power>params.threshold); %will give a row vector of indices that need to be converted to the original location in the raw data
paramStruct.pct_of_power = paramStruct.pct_of_power(detection_indices);

%convert these periodograms to the location in the the data of interest by
%converting the indices to samples using the window interval and the
%sample rate
periodogram_start_indices = (detection_indices-1)*samplerate*win_interval_sec+1;

%obtain the starting indices in terms of the entire study using the
%rem_indices vector
% starts = REM_indices(periodogram_start_indices);
starts = periodogram_start_indices;
stops = starts-1+win_length_sec*samplerate;  %or ..detectStruct.detectStruct.new_data(:)*event_length;

new_events = [starts(:), stops(:)];
min_samples = params.merge_within_sec*samplerate;
[new_events, merged_indices] = CLASS_events.merge_nearby_events(new_events,min_samples);
paramStruct.pct_of_power(merged_indices) = [];
detectStruct.new_events = new_events;

detectStruct.new_data = data;
detectStruct.paramStruct = paramStruct;


end