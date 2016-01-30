function detectStruct = detection_lm_dualthresh_raw(channel_indices, optional_params)
% detects PLM using dualthreshold method without any preprocessing
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
    sample_rate = params.sample_rate;
else
    sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));
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
            params.threshold_high_uV = 10; %8 uV above resting - presumably resting is 2uV
            params.threshold_low_uV = 8;
            params.min_duration_sec = 0.5;
            params.max_duration_sec = 10.0;
            params.merge_within_sec = 2;
            params.summer_order = 2;
            
            %         params.filter_order = 10;  %leave this alone - necessary for rr
            %         detector, but will not allow it to be adjusted here
            plist.saveXMLPlist(pfile,params);
        end
    end
end


%use other detection methods first...

%absolute value of data...
clean_data = abs(data);

%2 smooth the data with moving averager
ma.params.order = ceil(params.min_duration_sec*sample_rate);
ma.params.rms = 0;
clean_data = filter.filter_ma(clean_data,ma.params);

%3 increase SNR using 2 point moving integrator
integrator = ma;
integrator.params.order = params.summer_order;
clean_data = filter.filter_sum(clean_data,integrator.params);

%4 classify using dualthresholding
dualthreshold.params.threshold_high_uv = params.threshold_high_uV;
dualthreshold.params.threshold_low_uv = params.threshold_low_uV;
dualthreshold.params.merge_within_sec = params.merge_within_sec;
dualthreshold.params.min_dur_sec = params.min_duration_sec;
dualthreshold.params.sample_rate = sample_rate;
lm_detectStruct = detection.detection_dualthreshold(clean_data,dualthreshold.params);

% apply extra LM criteria (e.g. less than max duration)
max_duration = params.max_duration_sec*sample_rate;
min_duration = ma.params.order;

lm_events = lm_detectStruct.new_events;

if(~isempty(lm_events))
    lm_events(:,1) = lm_events(:,1)+ceil(ma.params.order/2);
    lm_events(:,2) = lm_events(:,2)-floor(ma.params.order/2);
    duration = (lm_events(:,2)-lm_events(:,1));
    clean_indices = duration<max_duration & duration>min_duration;
    lm_detectStruct.new_events = lm_events(clean_indices,:);
end;

%apply PLM rules now
detectStruct = lm_detectStruct;