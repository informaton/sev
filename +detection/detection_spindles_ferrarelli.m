function detectStruct = detection_spindles_ferrarelli(channel_index, optional_params)
%returns a two column vector of start and stop spindle indices found in
%DATA using the Fabio Ferrarelli's spindle detector method from the
%Psychiatry 2007 paper titled 'Reduced Sleep Spindle Activity in
%Schizophrenia Patients'
%
%The method was updated heavily as the paper did not adequately describe an
%effective method for locating spindles.  A major problem encountered by
%the paper was that though the input EEG signal was band passed, it still
%had high frequency components which caused it to oscillate above and belwo
%the thresholds producing short, clustered bursts of spindles.  To correct
%for this, the produced data was filtered again using a smoothing/averaging
%filter.  The mean and thresholds were then taken with respect to the
%smoother result.  This had to be done as the averaged signal dropped down
%in amplitude in comparison to the original band pass filtered signal
%
%
%FABIO_DLG is a structure containing the following fields
% .low_freq = 12;
% .high_freq = 15;
% .bp_filter_length = 100;
% .wintype = 'rectwin';
% .lower_scalar = 2;
% .upper_scalar = 5; -> should be 8 based on paper
% .smoothing_filter.window_length = 10;
global CHANNELS_CONTAINER;
% global FABIO_DLG;

%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_spindles_ferrarelli.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.smoothing_length_samples = 100; %FABIO_DLG.smoothing_filter.window_length;
        params.high_freq = 15; %FABIO_DLG.high_freq
        params.low_freq = 12; %FABIO_DLG.low_freq
        params.filter_order = 100; % FABIO_DLG.bp_filter_length;
        params.lower_threshold_factor = 2; %FABIO_DLG.lower_scalar;
        params.upper_threshold_factor = 8; %FABIO_DLG.upper_scalar;
        params.merge_together_within_sec = 0.25;
        plist.saveXMLPlist(pfile,params);
    end
end

params.wintype = 'hanning';
% params.wintype = FABIO_DLG.wintype;

% channel_obj = CHANNELS_CONTAINER.cell_of_channels{channel_index};
channel_obj.data = CHANNELS_CONTAINER.getData(channel_index);
channel_obj.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);

fs = channel_obj.sample_rate;

%1st bandpass to the 12-15Hz range
filterOrder = params.filter_order;
delay         = filterOrder/2;
zeropad = zeros(delay,1);
bp_range = [params.low_freq, params.high_freq]/fs*2;
bp_filter   = fir1(filterOrder-1,bp_range,feval(params.wintype,filterOrder));

abs_bp_data = abs(filter(bp_filter,1,channel_obj.data));
abs_bp_data = [abs_bp_data((delay+1):end);zeropad];

smoothing_kernel = params.smoothing_length_samples;

abs_bp_data_smoothed = filter(ones(1,smoothing_kernel)/smoothing_kernel,1,abs_bp_data);

m = mean(abs_bp_data_smoothed);
lower_thresh = m*params.lower_threshold_factor;
upper_thresh = m*params.upper_threshold_factor;


%apply logic to find spindles

%locate all start/stop pairings where the the lower threshold was crossed
% lower_thresh_indices = thresholdcrossings(abs_bp_data,ones(size(abs_bp_data))*lower_thresh);

lower_thresh_indices = thresholdcrossings(abs_bp_data_smoothed,lower_thresh);

spindles = zeros(size(lower_thresh_indices));
spindle_count = 0;

%go through each row looking for a spindle
for k=1:size(lower_thresh_indices,1)
    if(find(abs_bp_data(lower_thresh_indices(k,1):lower_thresh_indices(k,2))>upper_thresh,1))
        spindle_count = spindle_count+1;
        spindles(spindle_count,:) = lower_thresh_indices(k,:);
    end;
end;

if(spindle_count>0)
    spindles = spindles(1:spindle_count,:);
    spindles = merge_events(spindles,fs,params.merge_together_within_sec); %group the spindles together...
else
    spindles = [];
end;

detectStruct.new_data = abs_bp_data_smoothed;
detectStruct.new_events = spindles;
detectStruct.paramStruct = [];
