function detectStruct = detection_ocular_shw(data,varargin)
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
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input
% modified: 3/10/13 - better call to lpf

%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.filter_order = 10;
        params.low_pass_hz = 14;
        params.moving_window_sec = 0.15;
        params.threshold_uv = 70;
        params.merge_within_sec = 0.05;
        
        plist.saveXMLPlist(pfile,params);
    end
end

samplerate = params.samplerate;
%1. adaptively filter F3 channel

%%2. apply lowpass filter (0.5-8)
lpf_params.order=params.filter_order;
lpf_params.freq_hz = params.low_pass_hz;
lpf_params.samplerate = samplerate;
filtdata = filter.fir_lp(data,lpf_params);

% delay_lp = (params.filter_order)/2;
% 
% Bbandpass = fir1(params.filter_order,params.low_pass_hz/samplerate*2,'low');
% 
% filtdata = filter(Bbandpass,1,data);

%num pairings  ...


%% apply differentiator

differentiator_params.order=4;
filtdata  = filter.filter_differentiator(filtdata,differentiator_params);


% B_diff = 1/8*[1 2 0 -2 -1];
% delay_diff = floor(numel(B_diff)/2);
% filtdata = filter(B_diff,1,filtdata);

%% square the data
filtdata = filtdata.^2;

%% moving window average/integration
smooth_params.order=ceil(params.moving_window_sec * samplerate);
smooth_params.rms = 0;
integrated_data = filter.filter_ma(filtdata,smooth_params)*smooth_params.order;

% win_len = ceil(params.moving_window_sec * samplerate);
% B_ma = ones(1,win_len);
% avgdata = filter(B_ma,1,filtdata);
% 
% %account for the delay...
% delay = delay_diff+delay_lp;
% avgdata = [avgdata(delay+1:end); zeros(delay,1)];

%merge events that are within 1/25th of a second of each other samples of each other
new_events = thresholdcrossings(integrated_data, params.threshold_uv);
merge_distance = round(params.merge_within_sec*samplerate);
detectStruct.new_events = CLASS_events.merge_nearby_events(new_events,merge_distance);

detectStruct.new_data = integrated_data;
detectStruct.paramStruct = [];
