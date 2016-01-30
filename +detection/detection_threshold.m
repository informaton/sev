function detectStruct = detection_threshold(source_indices,optional_params)
%Generic detector that applies a dual threshold to the single channel
%provide (source_indices(1)).
% A detection begins when the signal rises above the first threshold and ends when
% it drops below the second threshold.
%
%
% Author Hyatt Moore IV
% Date: 5/10/2012

global CHANNELS_CONTAINER;

if(numel(source_indices)>100)
    data = source_indices;
    sample_rate = 100;
else
    data = CHANNELS_CONTAINER.getData(source_indices(1));
    sample_rate = CHANNELS_CONTAINER.getSamplerate(source_indices(1));
end

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = '+detection/detection_threshold.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.threshold_high_uv = 100;
        params.merge_within_sec = 1/20;
        params.min_dur_sec = 1/20;
        plist.saveXMLPlist(pfile,params);
    end
end


%merge events that are within 1/25th of a second of each other samples of each other
new_events = thresholdcrossings(data, params.threshold_high_uv);

if(~isempty(new_events))
    if(params.merge_within_sec>0)
        merge_distance = round(params.merge_within_sec*sample_rate);
        new_events = CLASS_events.merge_nearby_events(new_events,merge_distance);
    end
    
    if(params.min_dur_sec>0)
        diff_sec = (new_events(:,2)-new_events(:,1))/sample_rate;
        new_events = new_events(diff_sec>=params.min_dur_sec,:);
    end
end
detectStruct.new_events = new_events;
detectStruct.new_data = data;
detectStruct.paramStruct = [];
