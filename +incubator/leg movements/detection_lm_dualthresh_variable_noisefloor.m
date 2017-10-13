function detectStruct = detection_lm_dualthresh_variable_noisefloor(channel_indices, optional_params)
% detects PLM using dualthreshold method where the thresholds adjust based on a moving average power
%
% An epoch with high variance is likely to have more LM's.  And perhaps
% should have the power dropped?  --- maybe not so much...
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
% Written by Hyatt Moore IV, 6/9/2012, Boston, MA
%   updated 6/15/2012 Stanford, CA


global CHANNELS_CONTAINER;

if(numel(channel_indices)>20)
    data = channel_indices;
    params = optional_params;
    samplerate = params.samplerate;
else
    samplerate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));
    data = CHANNELS_CONTAINER.getData(channel_indices(1));
    %this allows direct input of parameters from outside function calls, which
    %can be particularly useful in the batch job mode
    if(nargin==2 && ~isempty(optional_params))
        params = optional_params;
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
            
            plist.saveXMLPlist(pfile,params);
        end
    end
end


%use other detection methods first...
% inst_power = data.*data;
%make it and save it for the future
ma_params.order=samplerate*params.average_power_window_sec;
ma_params.rms = 1;
noise_floor = filter.filter_ma(data,ma_params);

%alternatively, take as the average power of each epoch



%absolute value of data...
clean_data = abs(data); %moved this to rms = 1 in the below field

%2 smooth the data with moving averager
ma.params.order = ceil(params.min_duration_sec*samplerate);
ma.params.rms = 0;
clean_data = filter.filter_ma(clean_data,ma.params);

%3 increase SNR using 2 point moving integrator
% integrator = ma;
% integrator.params.order = params.summer_order;
% clean_data = filter.filter_sum(clean_data,integrator.params);

%4 classify using dualthresholding
variable_threshold_high_uv = params.threshold_high_uV+noise_floor;
variable_threshold_low_uv = params.threshold_low_uV+noise_floor;

%merge events that are within 1/25th of a second of each other samples of each other
new_events = variable_dualthresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv);

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
    new_events(:,1) = new_events(:,1)+ceil(ma.params.order/2);
    new_events(:,2) = new_events(:,2)-floor(ma.params.order/2);
    duration = (new_events(:,2)-new_events(:,1));
    clean_indices = duration<max_duration & duration>min_duration;
    new_events = new_events(clean_indices,:);
end;

detectStruct.new_events = new_events;
detectStruct.new_data = clean_data;
detectStruct.paramStruct = [];