function detectStruct = detection_dualthreshold(source_indices,optional_params)
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
    eye_data = source_indices;
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
    pfile = '+detection/detection_dualthreshold.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.threshold_first_uv = 100;
        params.threshold_second_uv = 50;
        plist.saveXMLPlist(pfile,params);
    end
end

%merge events that are within 1/25th of a second of each other samples of each other
new_events = thresholdcrossings(avgdata, params.threshold_uv);
merge_distance = round(1/20*sample_rate);
detectStruct.new_events = CLASS_events.merge_nearby_events(new_events,merge_distance);

detectStruct.new_data = avgdata;
detectStruct.paramStruct = [];
