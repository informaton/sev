function detectStruct = detection_lm_dualthresh_twopass_variable_noisefloor_mediator(data_In, optional_params)
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
% modified 6/14/2013: remove global references
%                       brought in outside function calls

%high_uv(x,nf(x)) = 0.5*x.*log(x) + high_threshold
%low_uv(x) - 0.25*high_uv(x,nf(x))
%
% the summer is not used in this case;
%
%high_uv is an approximation of the more computationally efficient noise floor high_uv function
%                 = 1/8*nf(x)^2+8 for nf(x)<8
%                 = scale*nf(x)+8 for nf(x) >= 8 and nf(x) <30
%                 = inf for nf(x)>30



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
data = data_In;

%merge events that are within 1/20th of a second of each other samples of each other
dur_samples_below_count = ceil(0.05*samplerate);
    
%first pass
[variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(data, params,samplerate);

new_events = variable_triplethresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);

%second pass - adjust the noise floor down to 1/2 the lower baseline threshold
% twopass = false;
% twopass= true;
% if(twopass)
if(~isempty(new_events))
    for k=1:size(new_events,1)
        data(new_events(k,1):new_events(k,2)) = variable_threshold_low_uv(new_events(k,1):new_events(k,2))/2;
    end

    [variable_threshold_low_uv, variable_threshold_high_uv,clean_data2] = getNoisefloor(data, params,samplerate);
    secondpass_events = variable_triplethresholdcrossings(clean_data2, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);
    if(~isempty(secondpass_events))
        new_events = sortrows([new_events;secondpass_events],1);
    end
end


if(~isempty(new_events))

    if(params.merge_within_sec>0)
        merge_distance = round(0.1*samplerate);
        new_events = merge_nearby_events(new_events,merge_distance);
    end    

    if(params.min_duration_sec>0)
        diff_sec = (new_events(:,2)-new_events(:,1))/samplerate;
        new_events = new_events(diff_sec>=params.min_duration_sec,:);
    end

    
    if(params.merge_within_sec>0)
        merge_distance = round(params.merge_within_sec*samplerate);
        new_events = merge_nearby_events(new_events,merge_distance);
    end
    
end

max_duration = params.max_duration_sec*samplerate;
min_duration = params.min_duration_sec*samplerate;

paramStruct = [];

if(~isempty(new_events))
%     new_events(:,1) = max(new_events(:,1)-ceil(ma.params.order/4),1);
%     new_events(:,2) = new_events(:,2)-floor(ma.params.order/4); %-dur_samples_below_count;
    duration = (new_events(:,2)-new_events(:,1));
    clean_indices = duration<max_duration & duration>min_duration;
    new_events = new_events(clean_indices,:);
    
    num_events = size(new_events,1);
    if(num_events>0)
        
        data = data_In;
        paramStruct.median = zeros(num_events,1);
        paramStruct.rms = zeros(num_events,1);
        paramStruct.abs_amplitude = zeros(num_events,1);
        paramStruct.dur_sec = zeros(num_events,1);
        paramStruct.density = zeros(num_events,1);
        
        paramStruct.auc = zeros(num_events,1);
        paramStruct.low_uV = zeros(num_events,1);
        paramStruct.high_uV = zeros(num_events,1);
        
        if(params.median_removal)
            held_events = true(size(new_events,1),1);
        end
        for n=1:num_events
            abs_datum = abs(data(new_events(n,1):new_events(n,2)));
            paramStruct.dur_sec(n) = (new_events(n,2)-new_events(n,1)+1)/samplerate;
            paramStruct.median(n) = median(abs_datum);
            
            %             paramStruct.rms(n) = sqrt(mean(datum.*datum));
            paramStruct.rms(n) = sqrt(mean(abs_datum.*abs_datum));
            paramStruct.abs_amplitude(n) = mean(abs_datum);
            paramStruct.auc(n) = trapz(abs_datum)/samplerate;
            paramStruct.density(n) = paramStruct.auc(n)/paramStruct.dur_sec(n);
            paramStruct.low_uV(n) = variable_threshold_low_uv(floor(new_events(n,1)+(new_events(n,2)-new_events(n,1))/2));
            paramStruct.high_uV(n) = variable_threshold_high_uv(floor(new_events(n,1)+(new_events(n,2)-new_events(n,1))/2));
            
            if(params.median_removal)             
                if(paramStruct.auc(n)<0.5*paramStruct.high_uV(n))
                    held_events(n) = false;
                end
            end   

        end
        if(params.median_removal)
            new_events = new_events(held_events,:);
            paramStruct.dur_sec = paramStruct.dur_sec(held_events);
            paramStruct.median = paramStruct.median(held_events);
            paramStruct.rms = paramStruct.rms(held_events);
            paramStruct.abs_amplitude = paramStruct.abs_amplitude(held_events);
            paramStruct.auc = paramStruct.auc(held_events);
            paramStruct.density = paramStruct.density(held_events);
            paramStruct.low_uV = paramStruct.low_uV(held_events);
            paramStruct.high_uV = paramStruct.high_uV(held_events);            
        end
        
    end;
    
    detectStruct.new_events = new_events;
    detectStruct.new_data = clean_data;
    detectStruct.paramStruct = paramStruct;

else
    detectStruct.new_events = [];
    detectStruct.new_data = clean_data;
    detectStruct.paramStruct = [];
end


end

function [variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(data, params, samplerate)
%     high_uv(x,nf(x)) = 0.5*x.*log(x) + high_threshold
    %apply noise floor rules now
    %1. turn off variable noise floor when below engagement threshold

    ma_params.order=samplerate*params.average_power_window_sec;
    ma_params.rms = 1;
    
    noisefloor = filter.filter_ma(data,ma_params);
    
    low_scale = params.threshold_low_uV/params.threshold_high_uV;
    
    disengage_indices = noisefloor>=params.noisefloor_uV_to_turnoff_detection;
    summer_indices = noisefloor<=params.threshold_low_uV;

    variable_threshold_high_uv = noisefloor.*(1+1*log(noisefloor+1)) + params.threshold_high_uV;  %version 3 and 4
    
    variable_threshold_high_uv(disengage_indices) = inf;    
    variable_threshold_low_uv = variable_threshold_high_uv*low_scale;
    
    %2 smooth absolute value of data with moving averager
    rms.params.order = ceil(samplerate*0.15);  %0.15 second time constant
    clean_data = filter.nlfilter_rms(data,rms.params);

    %3 increase SNR using 2 point moving integrator
    if(params.use_summer)
        integrator.params.rms = 1;
        integrator.params.order = params.summer_order;
        
        clean_data2 = filter.filter_sum(clean_data,integrator.params);
        clean_data(summer_indices) = clean_data2(summer_indices); %original detection method;
        
        
        variable_threshold_low_uv(summer_indices) = variable_threshold_low_uv(summer_indices)+params.threshold_low_uV;
        
        
        
    end
end

function cross_mat =  variable_triplethresholdcrossings(data, thresh_high, thresh_low,dur_below_samplecount)
% similar to dualthresholdcrossings, with the exception that the
% thresh_high and thresh_low are vectors of length(data).
% Written: Hyatt Moore IV
% February 6, 2013
% modificatoin from variable dualthresholdcrossings - after seeing the
% length that some lm's go on for.

cross_vec = false(size(data));
active_flag = false;
drop_count = 0;
last_above_middle_index = 1;
for k=1:numel(data)  
%     if(k>1179420)
%         disp(k);
%     end
    if(data(k)>thresh_high(k))
        active_flag = true;
        drop_count = 0;
    end
    if(active_flag)
        if(data(k)>(thresh_high(k)+thresh_low(k))/2)           
           last_above_middle_index = k;
        end
        if(data(k)<thresh_low(k))
            drop_count = drop_count+1;
            if(drop_count>dur_below_samplecount)
                active_flag = false;
                
                cross_vec(last_above_middle_index+1:k) = active_flag;  %remove the spots up until now that are not active
            end
        end
    end
    cross_vec(k) = active_flag;
end

cross_mat = thresholdcrossings(cross_vec);
end

    function [merged_events, merged_indices] = merge_nearby_events(events_in,min_samples)
        
        %merge events that are within min_samples of each other, into a
        %single event that stretches from the start of the first event
        %and spans until the last event
        %events_in is a two column matrix
        %min_samples is a scalar value
        %merged_indices is a logical vector of the row indices that
        %were merged from events_in. - these are the indices of the
        %in events_in that are removed/replaced
        if(nargin==1)
            min_samples = 100;
        end
        merged_indices = false(size(events_in,1),1);
        
        if(~isempty(events_in))
            merged_events = zeros(size(events_in));
            num_events_out = 1;
            num_events_in = size(events_in,1);
            merged_events(num_events_out,:) = events_in(1,:);
            for k = 2:num_events_in
                if(events_in(k,1)-merged_events(num_events_out,2)<min_samples)
                    merged_events(num_events_out,2) = events_in(k,2);
                    merged_indices(k) = true;
                else
                    num_events_out = num_events_out + 1;
                    merged_events(num_events_out,:) = events_in(k,:);
                end
            end;
            merged_events = merged_events(1:num_events_out,:);
        else
            merged_events = events_in;
        end;
    end

        