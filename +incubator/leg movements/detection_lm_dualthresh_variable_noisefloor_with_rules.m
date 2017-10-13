function detectStruct = detection_lm_dualthresh_variable_noisefloor_with_rules(channel_indices, optional_params)
% detects PLM using dualthreshold method where the thresholds adjust based on a moving average power
%  that accounts for other portions
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
% Written by Hyatt Moore IV, 1/9/2013, Stanford, CA
% modification of detection_lm_dualthresh_with_noisefloor.m


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
        params.threshold_high_uV = 8; %8 uV above resting - presumably resting is 2uV
        params.threshold_low_uV = 2;
        params.min_duration_sec = 0.5;
        params.max_duration_sec = 10.0;
        params.merge_within_sec = 2;
        params.summer_order = 2;
        params.average_power_window_sec = 30;  %calculate average power over consecutive windows of this duration in seconds
        params.noisefloor_uV_to_engage_variablethreshold = 5;
        params.noisefloor_uV_to_turnoff_detection = 12;
        params.noisefloor_scale_uV_to_engage = 8;
        params.noisefloor_scale = 2;
        plist.saveXMLPlist(pfile,params);
    end
end



%use other detection methods first...
% inst_power = data.*data;
%make it and save it for the future
ma_params.order=samplerate*params.average_power_window_sec;
ma_params.rms = 1;
noise_floor = filter.filter_ma(data,ma_params);

%apply noise floor rules now
%1. turn off variable noise floor when below engagement threshold
noisefloor_off_indices = noise_floor<params.noisefloor_uV_to_engage_variablethreshold;
% noisefloor_engage_indices = noise_floor>=params.noisefloor_uV_to_engage_variablethreshold & noise_floor<params.noisefloor_scale_uV_to_engage;
noisefloor_engage_and_scale_indices = noise_floor>=params.noisefloor_scale_uV_to_engage & noise_floor<params.noisefloor_uV_to_turnoff_detection;
detector_off_indices = noise_floor>=params.noisefloor_uV_to_turnoff_detection;

noise_floor(noisefloor_off_indices) = 0;

variable_threshold_low_uv = params.threshold_low_uV+noise_floor;

%raise the lower threshold up higher as well in these cases
variable_threshold_low_uv(noisefloor_engage_and_scale_indices) = variable_threshold_low_uv(noisefloor_engage_and_scale_indices)-params.threshold_low_uV*(1-params.noisefloor_scale);

noise_floor(noisefloor_engage_and_scale_indices) = noise_floor(noisefloor_engage_and_scale_indices)*params.noisefloor_scale;
noise_floor(detector_off_indices) = bitmax - params.threshold_high_uV;


variable_threshold_high_uv = params.threshold_high_uV+noise_floor;



%2 smooth absolute value of data with moving averager
ma.params.order = ceil(params.min_duration_sec*samplerate);
ma.params.rms = 1; %  clean_data = abs(data); %moved this to rms = 1 in the below field
clean_data = filter.filter_ma(data,ma.params);

%3 increase SNR using 2 point moving integrator
integrator = ma;
integrator.params.order = params.summer_order;
clean_data2 = filter.filter_sum(clean_data,integrator.params);
clean_data(noisefloor_off_indices) = clean_data2(noisefloor_off_indices); %original detection method;

%4 classify using dualthresholding


%merge events that are within 1/25th of a second of each other samples of each other
dur_samples_below_count = ceil(params.min_duration_sec*samplerate);
new_events = variable_dualthresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);

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

if(~isempty(new_events))
    new_events(:,1) = new_events(:,1)+ceil(ma.params.order/5);
    new_events(:,2) = new_events(:,2)-floor(ma.params.order/5);
    duration = (new_events(:,2)-new_events(:,1));
    clean_indices = duration<max_duration & duration>min_duration;
    new_events = new_events(clean_indices,:);
end;

detectStruct.new_events = new_events;
detectStruct.new_data = clean_data;
detectStruct.paramStruct = [];