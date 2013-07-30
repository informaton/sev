function detectStruct = detection_artifact_noisefloor(channel_indices, varargin)
% detects portions of data that exceed a desired noisefloor as determined
% by moving average over set order (e.g. number of seconds)
%
%  channel_indices(1) = channel to apply detection method too
%
% optional parameters are included for plm_threshold function and loaded
% from .plist file otherwise
%
% Written by Hyatt Moore IV, 1/10/2013, Stanford, CA
% modification of detection_lm_dualthresh_with_noisefloor.m


global CHANNELS_CONTAINER;

samplerate = 100;

if(numel(channel_indices)>20)
    data = channel_indices;
else
    samplerate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));
    data = CHANNELS_CONTAINER.getData(channel_indices(1));
end

%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    
    params = varargin{1};
    samplerate = params.samplerate;
    
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.average_power_window_sec = 30;  %calculate average power over consecutive windows of this duration in seconds
        params.noisefloor_uV_threshold = 12;
        params.merge_within_sec = 30;
        params.min_duration_sec = 15;
        plist.saveXMLPlist(pfile,params);
    end
end



%use other detection methods first...
% inst_power = data.*data;
%make it and save it for the future
ma_params.order=samplerate*params.average_power_window_sec;
ma_params.rms = 1;
noise_floor = filter.filter_ma(data,ma_params);

new_events = thresholdcrossings(noise_floor, params.noisefloor_uV_threshold);
paramStruct = [];
% apply extra LM criteria (e.g. less than max duration)
if(~isempty(new_events))
    if(params.merge_within_sec>0)
        merge_distance = round(params.merge_within_sec*samplerate);
        new_events = CLASS_events.merge_nearby_events(new_events,merge_distance);
    end
    
    if(params.min_duration_sec>0)
        %         diff_sec = (new_events(:,2)-new_events(:,1))/samplerate;
        %         new_events = new_events(diff_sec>=params.min_duration_sec,:);
        new_events = CLASS_events.cleanup_events(new_events,params.min_duration_sec*samplerate);
        num_events = size(new_events,1);
        paramStruct.avg_noisefloor = zeros(num_events,1);
        
        for k=1:num_events
            paramStruct.avg_noisefloor(k) = mean(noise_floor(new_events(k,1):new_events(k,2)));
        end
    end
end

detectStruct.new_events = new_events;
detectStruct.new_data = noise_floor;
detectStruct.paramStruct = paramStruct;