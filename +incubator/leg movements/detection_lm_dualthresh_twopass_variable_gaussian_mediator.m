function detectStruct = detection_lm_dualthresh_twopass_variable_gaussian_mediator(channel_indices, optional_params)
% detects PLM using dualthreshold method where the thresholds adjust based on a moving average power
%  that accounts for other portions and then does a second pass, with
%  adjustment to the noisefloor on account of detections made the first
%  time through.
%
% The algorithm is as follows
% (2-1) Smooth using 0.5 second moving averager (MA filter)
% (3-1) Run a 2-sample summer to increase SNR
% (4-1) Dual threshold at 10uV and 8uV
% (5-1) Prune using LM duration criteria
% (6-1) Classify PLM using AASM 2007 criteria
% (7-1) obtain HR data as described here:
%%
%  channel_indices(1) = LAT/RAT channel
%
% optional parameters are included for plm_threshold function and loaded
% from .plist file otherwise
%
% Written by Hyatt Moore IV, 1/18/2013, Stanford, CA
% modification of detection_lm_dualthresh_twopass_variable_noisefloor_With_rules.m

%high_uv(x,nf(x)) = 0.5*x.*log(x) + high_threshold
%low_uv(x) - 0.25*high_uv(x,nf(x))
%
% the summer is not used in this case;
%
%high_uv is an approximation of the more computationally efficient noise floor high_uv function
%                 = 1/8*nf(x)^2+8 for nf(x)<8
%                 = scale*nf(x)+8 for nf(x) >= 8 and nf(x) <30
%                 = inf for nf(x)>30



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
    
    params = optional_params;
    samplerate = params.samplerate;
    
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.use_summer = 0;  %apply summer or not.
        params.threshold_high_uV = 8; %8 uV above resting - presumably resting is 2uV
        params.threshold_low_uV = 2;
        params.min_duration_sec = 0.75;
        params.max_duration_sec = 10.0;
        params.merge_within_sec = 2;
        params.summer_order = 2;
        params.average_power_window_sec = 30;  %calculate average power over consecutive windows of this duration in seconds
        params.noisefloor_uV_to_engage_variablethreshold = 5;
        params.noisefloor_uV_to_turnoff_detection = 30;
        params.noisefloor_scale_uV_to_engage = 8;
        params.noisefloor_scale = 2;
        params.median_removal = 1;
        plist.saveXMLPlist(pfile,params);
    end
end
tic;
%merge events that are within 1/25th of a second of each other samples of each other
dur_samples_below_count = ceil(params.min_duration_sec*samplerate)*2;
    
%smooth absolute value of data with moving averager - this is called in one
%of the functions below
ma.params.order = ceil(params.min_duration_sec*samplerate);
ma.params.rms = 1; %  clean_data = abs(data); %moved this to rms = 1 in the below field

%use other detection methods first...
% inst_power = data.*data;
%make it and save it for the future

%first pass
[variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getGaussianNoisefloor(data, params,samplerate);

new_events = variable_dualthresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);

%second pass - adjust the noise floor down to 1/2 the lower baseline threshold
if(~isempty(new_events))
    for k=1:size(new_events,1)
        data(new_events(k,1):new_events(k,2)) = variable_threshold_low_uv(new_events(k,1):new_events(k,2))/2;
    end
    
    [variable_threshold_low_uv, variable_threshold_high_uv,clean_data] = getGaussianNoisefloor(data, params,samplerate);
    secondpass_events = variable_dualthresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);
    if(~isempty(secondpass_events))
        new_events = sortrows([new_events;secondpass_events],1);
    end
end

%4 classify using dualthresholding

% apply extra LM criteria (e.g. less than max duration)
% if(~isempty(new_events) && params.median_removal)
%     num_events = size(new_events,1);
%     held_events = true(num_events,1);
%     
%     for n=1:num_events
%         datum = data(new_events(n,1):new_events(n,2));
%         if(median(abs(datum))<mean(variable_threshold_low_uv(new_events(n,1):new_events(n,2))))
%             held_events(n) = false;
%         end
%     end
%     new_events = new_events(held_events,:);
% end
        

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
    if(num_events>0)
        
        %have to reset the data as it has changed due to pass by reference
        %function calls
        if(numel(channel_indices)>20)
            data = channel_indices;
        else
            samplerate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));
            data = CHANNELS_CONTAINER.getData(channel_indices(1));
        end
        paramStruct.median = zeros(num_events,1);
        paramStruct.rms = zeros(num_events,1);
        paramStruct.abs_amplitude = zeros(num_events,1);
        paramStruct.auc = zeros(num_events,1);
        paramStruct.low_uV = zeros(num_events,1);
        paramStruct.high_uV = zeros(num_events,1);
        
        if(params.median_removal)
            held_events = true(size(new_events,1),1);
        end
        for n=1:num_events
            abs_datum = abs(data(new_events(n,1):new_events(n,2)));
            
            paramStruct.median(n) = median(abs(abs_datum));
            
            %             paramStruct.rms(n) = sqrt(mean(datum.*datum));
            paramStruct.rms(n) = sqrt(mean(abs_datum.*abs_datum));
            paramStruct.abs_amplitude(n) = mean(abs_datum);
            paramStruct.auc(n) = trapz(abs_datum)/samplerate;
            paramStruct.low_uV(n) = variable_threshold_low_uv(floor(new_events(n,1)+(new_events(n,2)-new_events(n,1))/2));
            paramStruct.high_uV(n) = variable_threshold_high_uv(floor(new_events(n,1)+(new_events(n,2)-new_events(n,1))/2));
            
            
            if(params.median_removal)
                %                 if(paramStruct.median(n)<variable_threshold_low_uv+mean(variable_threshold_low_uv(new_events(n,1):new_events(n,2))))
                %                 if(paramStruct.median(n)<variable_threshold_low_uv+variable_threshold_low_uv(floor(new_events(n,1)+(new_events(n,2)-new_events(n,1))/2)))
                if(paramStruct.abs_amplitude(n)<0.8*variable_threshold_high_uv(floor(new_events(n,1)+(new_events(n,2)-new_events(n,1))/2)))
                    held_events(n) = false;
                end
                %             end
            end   

        end
        if(params.median_removal)
            new_events = new_events(held_events,:);
            paramStruct.median = paramStruct.median(held_events);
            paramStruct.rms = paramStruct.rms(held_events);
            paramStruct.abs_amplitude = paramStruct.abs_amplitude(held_events);
            paramStruct.auc = paramStruct.auc(held_events);
        end
        
    end;

detectStruct.new_events = new_events;
detectStruct.new_data = clean_data;
detectStruct.paramStruct = paramStruct;
toc

end


