function detectStruct = detection_ocular_variable_dualthreshold(data,params,varargin)
%Apply a dual threshold to single channel - prepped for ocular movements
% (e.g. LOC is source_indices(1))
% Detection begins when the signal rises above the first threshold and ends when
% it drops below the second threshold.
% Noise rules are incorporated to handle adjustments
%
% Author Hyatt Moore IV
% Date: 1/23/2013
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input
% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode


% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.threshold_high_uV = 20;
defaultParams.threshold_low_uV = 10;
defaultParams.merge_within_sec = 0.05;
defaultParams.average_power_window_sec = 30;
defaultParams.noisefloor_uV_to_turnoff_detection = 50;
defaultParams.min_duration_sec = 0.1;
defaultParams.use_summer = 1;

% return default parameters if no input arguments are provided.
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
    
    
    
    samplerate = params.samplerate;

    
    ma.params.order = ceil(params.min_duration_sec*samplerate);
    params.max_duration_sec = 30;
    params.summer_order = 2;
    %merge events that are within 1/25th of a second of each other samples of each other
    dur_samples_below_count = ceil(params.merge_within_sec*samplerate);
    
    %first pass - clean_data is ma smoothed and possibly 2-point
    %integrated/summed
    [variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(data, params,samplerate);
    
    new_events = variable_dualthresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);
    
    %second pass - adjust the noise floor down to 1/2 the lower baseline threshold
    if(~isempty(new_events))
        for k=1:size(new_events,1)
            data(new_events(k,1):new_events(k,2)) = variable_threshold_low_uv(new_events(k,1):new_events(k,2))/2;
        end
        
        [variable_threshold_low_uv, variable_threshold_high_uv,clean_data] = getNoisefloor(data, params,samplerate);
        secondpass_events = variable_dualthresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);
        if(~isempty(secondpass_events))
            new_events = sortrows([new_events;secondpass_events],1);
        end
    end
    
    %4 classify using dualthresholding
    
    % apply extra LM criteria (e.g. less than max duration)
    if(~isempty(new_events))
        if(params.merge_within_sec>0)
            merge_distance = round(params.merge_within_sec*samplerate);
            new_events = CLASS_events.merge_nearby_events(new_events,merge_distance);
        end
        
        if(params.min_duration_sec>0)
            diff_sec = (new_events(:,2)-new_events(:,1))/samplerate;
            new_events = new_events(diff_sec>=params.min_duration_sec,:);
        end
    end
    
    max_duration = params.max_duration_sec*samplerate;
    min_duration = params.min_duration_sec*samplerate;
    
    paramStruct = [];
    
    if(~isempty(new_events))
        new_events(:,1) = max(new_events(:,1)-ceil(ma.params.order/4),1);
        new_events(:,2) = new_events(:,2)-floor(ma.params.order/4); %-dur_samples_below_count;
        duration = (new_events(:,2)-new_events(:,1));
        clean_indices = duration<max_duration & duration>min_duration;
        new_events = new_events(clean_indices,:);
        
        num_events = size(new_events,1);
        %     if(num_events>0)
        %
        %         %have to reset the data as it has changed due to pass by reference
        %         %function calls
        %         if(numel(channel_indices)>20)
        %             data = channel_indices;
        %         else
        %             samplerate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));
        %             data = CHANNELS_CONTAINER.getData(channel_indices(1));
        %         end
        %         paramStruct.median = zeros(num_events,1);
        %         paramStruct.rms = zeros(num_events,1);
        %         paramStruct.abs_amplitude = zeros(num_events,1);
        %         paramStruct.auc = zeros(num_events,1);
        %
        %         for n=1:num_events
        %             datum = data(new_events(n,1):new_events(n,2));
        %             paramStruct.median(n) = median(abs(datum));
        %             paramStruct.rms(n) = sqrt(mean(datum.*datum));
        %             paramStruct.abs_amplitude(n) = mean(abs(datum));
        %             paramStruct.auc(n) = trapz(abs(datum))/samplerate;
        %         end
        %     end
        %
    end;
    
    detectStruct.new_events = new_events;
    detectStruct.new_data = clean_data;
    detectStruct.paramStruct = paramStruct;
end
