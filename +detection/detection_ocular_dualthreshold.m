function detectStruct = detection_ocular_dualthreshold(data, varargin)
%Apply a dual threshold to single channel - prepped for ocular movements
% (e.g. LOC is source_indices(1))
% Detection begins when the signal rises above the first threshold and ends when
% it drops below the second threshold.
% Noise rules are incorporated to handle adjustments
%

% Author Hyatt Moore IV
% Date: 5/10/2012
%modified 3/1/2013 - remove global references and use varargin

if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.threshold_high_uv = 30;
        params.threshold_low_uv = 10;
        params.merge_within_sec = 0.05;
        params.min_dur_sec = 0.1;
        plist.saveXMLPlist(pfile,params);
        
    end
end


samplerate = params.samplerate;

%merge events that are within 1/25th of a second of each other samples of each other
new_events = dualthresholdcrossings(abs(data), params.threshold_high_uv,params.threshold_low_uv);
% new_events = triplethresholdcrossings(data, params.threshold_high_uv,params.threshold_low_uv, params.dur_below_samplecount)
if(~isempty(new_events))
    
    if(params.merge_within_sec>0)
        merge_distance = round(params.merge_within_sec*samplerate);
        new_events = CLASS_events.merge_nearby_events(new_events,merge_distance);
    end
    
    if(params.min_dur_sec>0)
        diff_sec = (new_events(:,2)-new_events(:,1))/samplerate;
        new_events = new_events(diff_sec>=params.min_dur_sec,:);
    end
end
detectStruct.new_events = new_events;
detectStruct.new_data = data;
detectStruct.paramStruct = [];