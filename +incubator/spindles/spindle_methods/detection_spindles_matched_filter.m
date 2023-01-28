function detectStruct = detection_spindles_matched_filter(channel_index,optional_params)
global CHANNELS_CONTAINER;

data = CHANNELS_CONTAINER.getData(channel_index);
sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = '+detection/detection_spindles_matched_filter.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.low_freq = SPINDLE_DLG.low_freq;
        params.high_freq = SPINDLE_DLG.high_freq;
        params.rms_long_dur_min = SPINDLE_DLG.rms_long_min;
        params.rms_short_dur_sec = SPINDLE_DLG.rms_short_sec;
        params.threshold_scale_factor = SPINDLE_DLG.scale_factor;
        params.filter_order = SPINDLE_DLG.order;

        plist.saveXMLPlist(pfile,params);
    end
end

x = 1:params.filter_order;
t = x/sample_rate;
A =1; %carrier
M = 1; %message
fm = 1;
fc = 12.5;
spindle_template = A*(1-M*cos(2*pi*fm*t)).*sin(2*pi*fc*t);

t = [rand(1,500),y,rand(1,600)];
f = filter(fliplr(y),1,t)
f = filter(y,1,t)
close all;plot(A*(1+M*cos(2*pi*x/100)).*sin(2*pi*fc*x/100))

%this is currently unused...
% params.win_type = SPINDLE_DLG.win_type;
b = spindle_template;
filtdata = filter(b,1,channel_obj.data);

%account for the delay...
filtdata = [filtdata(delay+1:end); zeros(delay,1)];

spindle_crossings = thresholdcrossings(filtdata,100);
detectStruct.new_data = filtdata;
detectStruct.new_events = spindle_crossings;
detectStruct.paramStruct = [];
