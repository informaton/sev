%> @file detection_peaks.cpp
%> Generic peak detection algorithm.
%> @brief Find peaks or valleys in a signal.
%> @note Written 1/29/2016 copyright Hyatt Moore IV

function detectStruct = detection_peaks(data, params, ~)

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
    peaksVec = sev_findpeaks(data);
    new_events = [peaksVec(:), peaksVec(:)];
    
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
