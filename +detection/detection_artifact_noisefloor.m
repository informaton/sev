%> @file
%> @brief Detects portions of data that exceed a desired noisefloor as determined
%> by moving average over set order (e.g. number of seconds)
%======================================================================
%> @brief Detects portions of data that exceed a desired noisefloor as determined
%> by moving average over set order (e.g. number of seconds)
%> @param data Signal data as a column vector.  
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c average_power_window_sec Calculate average power over consecutive windows of this duration in seconds
%> @li @c noisefloor_uV_threshold Detection threshold in micro-Volts.
%> @li @c merge_within_sec Window duration to merge events within.
%> @li @c min_duration_sec Mininum duration of an event in seconds.
%>
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Copy of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. one per row).
%> @li @c paramStruct Structure with following field 
%> @li @c paramStruct.avg_noisefloor Vector with the same numer of elements
%> as rows of @c new_events.  Each value contains the average power of the
%> signal during the corresponding detected event.
function detectStruct = detection_artifact_noisefloor(data, params, stageStruct)

% optional parameters are included for plm_threshold function and loaded
% from .plist file otherwise
%
% Written by Hyatt Moore IV, 1/10/2013, Stanford, CA
% modification of detection_lm_dualthresh_with_noisefloor.m

if(nargin<2 || isempty(params))

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

samplerate = params.samplerate;



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