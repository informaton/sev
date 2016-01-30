function detectStruct = detection_lm_ferri(channel_index, optional_params)
% The criteria taken for this Leg Movement (LM) detector comes from the
% paper "New Approaches to the Study of Periodic Leg Movements During Sleep
% in Restless Legs Syndrome" by Raffaele Ferri, et al.
%
% The paper was published in SLEEP, Vol. 29, No. 6, 2006 and the detection
% algorithm used was published in SLEEP (Vol 28, No. 8), August 2005
% (pp. 998-1004).
% These papers were influential in the AASM 2007's determination of LM and
% PLM scoring criteria.
%
% Leg Movement parameters
%   Duration  = 0.5 - 15 Seconds in length
%   Amplitude starts at greater than 7 uV and ends when sliding window
%   (0.5 s) average falls below 2uV.  
%   AUC - area under the curve - sum of the detected leg movement
%   (rectified values) divided by the duration in samples.
%   Sleep stage - stage that the LM occurred in (Stage 0 is ignored)
%   Interval 1 - these are for PLM criteria
%   Interval 2 - for PLM criteria

global CHANNELS_CONTAINER;
global STAGES;
global DEFAULTS;

% LEG_channel = CHANNELS_CONTAINER.cell_of_channels{channel_index};
LEG_channel.data = CHANNELS_CONTAINER.getData(channel_index);
LEG_channel.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);

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
%         params.operation = 'mean';
%         params.filter_order = 50;%1/2 second worth at 100Hz sampling rate
        params.lower_threshold_uV = 2; 
        params.upper_threshold_uV = 9;  %7 uV above resting - presumably resting is 2uV
        params.min_duration_sec = 0.5;
        params.max_duration_sec = 10.0;
        params.filter_hp_freq_Hz = 15;
        params.sliding_window_len_sec = 0.5; %the length of the sliding window in seconds that was applied to find
            %when the amplitude of detected LM dropped below 2uV.

        plist.saveXMLPlist(pfile,params);
        
    end
end
params.filter_order = 100;

params.merge_lm_within_sec = params.min_duration_sec;

params.stages2exclude = [0,7];

detectStruct.paramStruct = [];

%1. High pass filter the channel
if(params.filter_hp_freq_Hz~=0)
    LM_DLG.order = params.filter_order;
    LM_DLG.w = params.filter_hp_freq_Hz; %20+ Hz
    
    n = LM_DLG.order;
    delay = (n)/2;
    % b = fir1(n,LM_DLG.w/LEG_channel.sample_rate*2,'low');
    b = fir1(n,LM_DLG.w/LEG_channel.sample_rate*2,'high');
    
    LM_line = filter(b,1,LEG_channel.data);

    %account for the delay...
    LM_line = [abs(LM_line(delay+1:end)); zeros(delay,1)];
else
    LM_line = abs(LEG_channel.data);
end

%obtain the high portions as candidates to consider
LM_above_thresh_high = find(LM_line >=params.upper_threshold_uV);

window_len = params.sliding_window_len_sec*LEG_channel.sample_rate;  %e.g. 50 samples for 0.5s at 100-Hz sampling
max_dur =params.max_duration_sec*LEG_channel.sample_rate;

data_length = numel(LM_line);

LM_above_thresh_high = LM_above_thresh_high(LM_above_thresh_high<data_length-max_dur-1);
LM_below_thresh_low = LM_above_thresh_high;


ma_b = ones(1,window_len)/window_len;
ma_a = 1;

avg_LM_line = filter(ma_b,ma_a,LM_line);  %find the moving average value for the whole signal - which is faster than replicating the sum over and over again as done
%originally
%now go back over and find the parts where it broke the first part of these

%handle initial case
if(isempty(LM_above_thresh_high))
    detectStruct.new_events = [];
    detectStruct.new_data = LM_line;
    
    AUC = [];
    paramStruct.AUC = AUC;
    detectStruct.paramStruct = paramStruct;

else
    start = LM_above_thresh_high(1);
    cand = find(avg_LM_line(start:start+max_dur)<params.lower_threshold_uV,1);
    if(~isempty(cand))
        LM_below_thresh_low(1) = start+cand;
    end
    last_crossed_index = LM_below_thresh_low(1);
    
    for k=2:numel(LM_above_thresh_high)
        %find the place where slinding window avg falls below
        %LM_below_thresh_low
        start = LM_above_thresh_high(k);
        if(start>last_crossed_index)
            cand = find(avg_LM_line(start:start+max_dur)<params.lower_threshold_uV,1);
            if(~isempty(cand))
                LM_below_thresh_low(k) = start+cand;
                last_crossed_index = LM_below_thresh_low(k);
            end
        end
        %way tooo slow here ...
        
        %     LM_below_thresh_low(k) = MA_thresholdIndex(LM_line, data_length, LM_above_thresh_high(k), window_len, params.lower_threshold_uV);
    end
    
    LM_candidates = [LM_above_thresh_high(:),LM_below_thresh_low(:)];
    
    LM_dur_range = ceil([params.min_duration_sec, params.max_duration_sec]*LEG_channel.sample_rate);
    
    %merge within minimum length criteria for leg movements
    % LM_candidates = CLASS_events.merge_nearby_events(LM_candidates,LM_dur_range(1));
    
    %2.  apply LM lm duration criteria...
    lm_dur = diff(LM_candidates');
    LM_candidates = LM_candidates(lm_dur>=LM_dur_range(1) & lm_dur<=LM_dur_range(2),:);
    
    %3.  merge movements within 0.5, or 4 seconds of each other - ? where does this
    %come from?
    min_dur_sec = params.merge_lm_within_sec;
    min_samples = round(min_dur_sec*LEG_channel.sample_rate);
    if(min_samples>0)
        LM_candidates = CLASS_events.merge_nearby_events(LM_candidates,min_samples);
    end
    
    %4.  Exclude LM's from wake stages
    epochs = sample2epoch(LM_candidates,DEFAULTS.standard_epoch_sec,LEG_channel.sample_rate);
    stages = STAGES.line(epochs);
    
    excluded_indices = false(size(epochs,1),2); %have to take into account start and stops being in different epochs
    
    for k=1:numel(params.stages2exclude)
        stage2exclude = params.stages2exclude(k);
        excluded_indices = excluded_indices|stages==stage2exclude;
    end
    
    excluded_indices = excluded_indices(:,1)|excluded_indices(:,2);
    
    % stages = stages(~excluded_indices);
    
    LM = LM_candidates(~excluded_indices,:);
    detectStruct.new_events = LM;
    detectStruct.new_data = LM_line;
    
    duration = diff(LM')'+1;
    AUC = zeros(size(duration)); %area under the curve
    for k =1:numel(AUC)
        AUC(k) = sum(LM_line(LM(k,1):LM(k,2)))/duration(k);
    end
    paramStruct.AUC = AUC;
    
    %the following are now part of the normal event output for all event
    %detections and have been removed here as it is redundant
    % paramStruct.stage = stages;
    %duration_sec = duration/LEG_channel.sample_rate;
    %paramStruct.duration_sec = duration_sec;
    
    
    %parameter struct can include the duration, stage, AUC, etc.
    detectStruct.paramStruct = paramStruct;
end

end


function stop_index = MA_thresholdIndex(data, data_length, start_index, window_len, threshold)
%returns stop_index, the index where the moving average of length
%window_len, starting at start_index, falls below threshold
if(start_index >= data_length-window_len)
    stop_index = window_len;
else
    adjusted_threshold = threshold*window_len;  %this multiplications cuts out a division step in the for loop below
    for k=start_index:data_length-window_len
        if(sum(data(k:k+window_len))< adjusted_threshold)
            break;
        end
    end
    stop_index = k;
end
end