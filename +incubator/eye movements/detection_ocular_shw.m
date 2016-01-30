function detectStruct = detection_ocular_shw(source_indices,optional_params)
%detect eye movements from an EOG channel for Steven H. Woodward's dataset
%which uses an HEOG and VEOG montage setup over the left eye (closer to
%F3).
%Method is adapted from QRS detection algorithm from 1985 paper,
%"Real-Time QRS Detection Algorithm" by Jiapu Pan and
%Willis Tompkins which was originally implemented in assembly language this
%algorithm uses a single ECG lead, bandpass filtering (originally cascade
%of high and low-pass filters), derivative filtering, squaring, moving
%integration, and multiple thresholding and adaptation.
%
% This method is lite, and only uses the final, integrated signal as
% opposed to the original paper which used more and did further processing
% which I found to be unnecessary here.
%
% source_indices(1) = VEOG
% source_indices(2) = HEOG
%
% Ideally, the signal should have F3 adaptively filtered out and then be
% lowpass filtered at 8 Hz to remove noise and finally something must be
% done to remove breathing artifact
%
% Author Hyatt Moore IV
% Date: 5/10/2012

global CHANNELS_CONTAINER;

if(numel(source_indices)>100)
    eye_data = source_indices;
    sample_rate = 100;
else
    eye_data = CHANNELS_CONTAINER.getData(source_indices(1));
%     heog_data = CHANNELS_CONTAINER.getData(source_indices(2));
    sample_rate = CHANNELS_CONTAINER.getSamplerate(source_indices(1));
end

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
        params.filter_order = 10;
        params.low_pass_hz = 8;
        params.moving_window_sec = 0.15;
        params.threshold_uv = 100;
        plist.saveXMLPlist(pfile,params);
    end
end


%1. adaptively filter F3 channel

%%2. apply lowpass filter (0.5-8)
delay_lp = (params.filter_order)/2;

Bbandpass = fir1(params.filter_order,params.low_pass_hz/sample_rate*2,'low');

filtdata = filter(Bbandpass,1,eye_data);

%num pairings  ...


%% apply differentiator
B_diff = 1/8*[-1 -2 0 2 1];
delay_diff = floor(numel(B_diff)/2);
filtdata = filter(B_diff,1,filtdata);

%% square the data
filtdata = filtdata.^2;

%% moving window average/integration
% params.moving_window_sec = 0.15; %this value determined empirically by authors
win_len = ceil(params.moving_window_sec * sample_rate);
B_ma = 1/win_len*ones(1,win_len);
B_ma = ones(1,win_len);
avgdata = filter(B_ma,1,filtdata);

%account for the delay...
delay = delay_diff+delay_lp;
avgdata = [avgdata(delay+1:end); zeros(delay,1)];


%merge events that are within 1/25th of a second of each other samples of each other
new_events = thresholdcrossings(avgdata, params.threshold_uv);
merge_distance = round(1/20*sample_rate);
detectStruct.new_events = CLASS_events.merge_nearby_events(new_events,merge_distance);

detectStruct.new_data = avgdata;
detectStruct.paramStruct = [];
