%> @file
%> @brief Eye movement detector using a dual amplitude threshold for
%> detections.
%======================================================================
%> @brief Detects eye movements from an EOG channel using two amplitude thresholds.
%> @param data Sampled EOG signal as a column vector.  
%> @param params A structure for variable parameters passed in
%> with following fields  {default}
%> @li @c params.threshold_high_uv Upper amplitude threshold in uV; this must be crossed to begin a detection {30}
%> @li @c params.threshold_low_uv Lower amplitude threshold in uV; signal must fall below this to register event completion {10}
%> @li @c params.merge_within_sec Duration to merge consecutive events within {0.05}
%> @li @c params.min_dur_sec Minimum duration for detected events in seconds {0.1}
%>
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Duplicate of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Unused (i.e. [])
function detectStruct = detection_ocular_dualthreshold(data, params, stageStruct)
%Apply a dual threshold to single channel - prepped for ocular movements
% (e.g. LOC is source_indices(1))
% Detection begins when the signal rises above the first threshold and ends when
% it drops below the second threshold.
% Noise rules are incorporated to handle adjustments
%

% Author Hyatt Moore IV
% Date: 5/10/2012
%modified 3/1/2013 - remove global references and use varargin
%modified 11/5/2013 - Update and use params and stageStruct instead of varargin

if(nargin<2 || isempty(params))
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
end