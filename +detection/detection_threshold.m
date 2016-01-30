function detectStruct = detection_threshold(data, params, ~)
%Generic detector that applies a dual threshold to the single channel
%provide (source_indices(1)).
% A detection begins when the signal rises above the first threshold and ends when
% it drops below the second threshold.
%
%
% Author Hyatt Moore IV
% Date: 5/10/2012
% Migrated in on 1/29/2016 by Hyatt Moore IV
% return default parameters if no input arguments are provided.
%> @note This relies on the method @c thresholdcrossings which is in sev's
%> @c auxiliary/ folder

%make it and save it for the future
defaultParams.threshold_high_uv = 100;
defaultParams.merge_within_sec = 0.05;
defaultParams.min_dur_sec = 0.05;

if(nargin==0)
    detectStruct = defaultParams;
else
    
    if(nargin<2 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future            
            params = defaultParams;
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
end
