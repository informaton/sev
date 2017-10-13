function detectStruct = detection_plm_calculator(channel_cell_data, optional_params, stageStruct)
% detects PLM using selected detection and preprocessing methods
%
%
%
% HR is calculalated using
% channcel_indices(2) (ECG) (see rr_simple).  Timelocked cardiac
% accelerations (cal for cardiovascular acceleration/arousal lock)
% parameters are computed from matched PLM-cardiac cycles using the methods
% introduced by Winkelman in his 1999 paper.
%
%  channel_indices(1) = LAT/RAT channel
%  channel_indices(2) = ECG 
%
% Written by Hyatt Moore IV, 6/15/2012
%
% updated later on

% 1/9/2013 -  adjustable noise floor with rules



%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
%         params.samplerate = 100;
        params.detector = 12;
        params.filter_with_anc = 1; %adaptively filter ECG (0 = no; 1 = yes)
        params.min_duration_sec = 0.75;
        params.average_power_window_sec = 20;  %calculate average power over consecutive windows of this duration in seconds
        params.merge_within_sec = 2.0;
        params.use_summer = 0;
        params.median_removal = 0;        
        plist.saveXMLPlist(pfile,params);
    end
end

% params.samplerate = 100;
samplerate = params.samplerate;

params.HR_seconds_after = 10; %number of seconds to look at HR variability after LM hit
params.HR_seconds_before = 10; %number of seconds to look at before LM hit


if(~iscell(channel_cell_data))
    channel_cell_data = {channel_cell_data};
end

%adaptive noise cancel if selected
if(params.filter_with_anc)
    %1. adaptively cancel noise from ECG using recursive least squares method
    data = filter.anc_rls(channel_cell_data{1},channel_cell_data{2});    
else
    data = channel_cell_data{1};
end

switch params.detector
    
    case 13 % fifth approach with gaussian filter instead of moving average...ourth approach to handling noise floor - uses two passes and one function for noisefloor handling; apply summer for low noise
        params.threshold_high_uV = 8; %8 uV above resting baseline
        params.threshold_low_uV = 2;
        params.max_duration_sec = 10.0;
        params.summer_order = 2;
        params.noisefloor_uV_to_engage_variablethreshold = 5;
        params.noisefloor_uV_to_turnoff_detection = 30;
        params.dualthresh_variable_rule.median_removal = 1;
        
        lm_detectStruct = detection.detection_lm_dualthresh_twopass_variable_gaussian_mediator(data,params);
        
    case 12 % fourth approach to handling noise floor - uses two passes and one function for noisefloor handling; apply summer for low noise
            params.threshold_high_uV = 8; %8 uV above resting baseline
        params.threshold_low_uV = 2;
        params.max_duration_sec = 10.0;
        params.summer_order = 2;
        params.noisefloor_uV_to_turnoff_detection = 50;
        
        lm_detectStruct = detection.detection_lm_dualthresh_twopass_variable_noisefloor_mediator(data,params);
        
%116 uses summer and gets lots of the extra stuff as a parameter
%114 is the non summer that Emmanuel likes
%115 is like 116, but does not keep the parameters
     case 11 % fourth approach to handling noise floor - uses two passes and one function for noisefloor handling; apply summer for low noise
        params.threshold_high_uV = 8; %8 uV above resting baseline
        params.threshold_low_uV = 2;
        params.max_duration_sec = 10.0;
        params.summer_order = 2;
        params.noisefloor_uV_to_turnoff_detection = 30;
        
        
%         params.dualthresh_variable_rule.min_duration_sec = 0.5;
%         params.dualthresh_variable_rule.noisefloor_uV_to_turnoff_detection = 20;
%         params.noisefloor_uV_to_engage_variablethreshold = 5;
        
        lm_detectStruct = detection.detection_lm_dualthresh_twopass_variable_noisefloor(data,params);
        
     case 10 % third approach to handling noise floor - uses two passes and one function for noisefloor handling; do not apply noise floor.
         params.threshold_high_uV = 8; %8 uV above resting baseline
         params.threshold_low_uV = 2;
         params.max_duration_sec = 10.0;
         params.summer_order = 2;
         params.noisefloor_uV_to_turnoff_detection = 30;

         
%         params.dualthresh_variable_rule.min_duration_sec = 0.5;
%         params.dualthresh_variable_rule.noisefloor_uV_to_turnoff_detection = 12;
%         params.dualthresh_variable_rule.merge_within_sec = 1.0;
%         params.dualthresh_variable_rule.average_power_window_sec = 30;  %calculate average power over consecutive windows of this duration in seconds
%         params.dualthresh_variable_rule.use_summer = 0;

        lm_detectStruct = detection.detection_lm_dualthresh_twopass_variable_noisefloor(data,params);
    
    case 9 % second rule based approach to noise floor - uses two passes and three rules for noise floor handling
        params.threshold_high_uV = 8; %8 uV above resting baseline
        params.threshold_low_uV = 2;
        params.max_duration_sec = 10.0;
        params.summer_order = 2;
        params.noisefloor_uV_to_engage_variablethreshold = 5;
        params.noisefloor_uV_to_turnoff_detection = 30;
        
        %         params.dualthresh_variable_rule.min_duration_sec = 0.5;
        %         params.dualthresh_variable_rule.noisefloor_uV_to_turnoff_detection = 12;
        %         params.dualthresh_variable_rule.merge_within_sec = 1.0;
        %         params.dualthresh_variable_rule.average_power_window_sec = 30;  %calculate average power over consecutive windows of this duration in seconds
        %         params.dualthresh_variable_rule.use_summer = 0;
        
        params.noisefloor_scale_uV_to_engage = 8;
        params.noisefloor_scale = 2;

        params.noisefloor_uV_to_engage_variablethreshold = 2;
        params.noisefloor_scale_uV_to_engage = 8;
        params.noisefloor_scale = 2;
        lm_detectStruct = detection.detection_lm_dualthresh_twopass_variable_noisefloor_with_rules(data,params);
        
    case 8 % second rule based approach to noise floor
                 params.threshold_high_uV = 8; %8 uV above resting baseline
         params.threshold_low_uV = 2;
         params.max_duration_sec = 10.0;
         params.summer_order = 2;
         params.noisefloor_uV_to_engage_variablethreshold = 5;
         params.noisefloor_uV_to_turnoff_detection = 30;
         
%         params.dualthresh_variable_rule.min_duration_sec = 0.5;
%         params.dualthresh_variable_rule.merge_within_sec = 1.0;
%         params.dualthresh_variable_rule.average_power_window_sec = 40;  %calculate average power over consecutive windows of this duration in seconds

        params.noisefloor_uV_to_engage_variablethreshold = 2;
        params.noisefloor_scale_uV_to_engage = 8;
        params.noisefloor_scale = 2;

        lm_detectStruct = detection.detection_lm_dualthresh_variable_noisefloor_with_rules(data,params);
%         lm_detectStruct = detection.detection_lm_dualthresh_twopass_variable_noisefloor_with_rules(data,params.dualthresh_variable_rule);
        
        %this creates number 107
    case 7 % rule based approach to noise floor 
        
        params.dualthresh_variable_rule.threshold_high_uV = 10; %8 uV above resting - presumably resting is 2uV
        params.dualthresh_variable_rule.threshold_low_uV = 5;
        params.dualthresh_variable_rule.min_duration_sec = 0.5;
        params.dualthresh_variable_rule.max_duration_sec = 10.0;
        params.dualthresh_variable_rule.merge_within_sec = 2;
        params.dualthresh_variable_rule.summer_order = 2;
        params.dualthresh_variable_rule.average_power_window_sec = 30;  %calculate average power over consecutive windows of this duration in seconds
        params.dualthresh_variable_rule.noisefloor_uV_to_engage_variablethreshold = 4;
        params.dualthresh_variable_rule.noisefloor_uV_to_turnoff_detection = 30;
        params.dualthresh_variable_rule.noisefloor_scale_uV_to_engage = 8;
        params.dualthresh_variable_rule.noisefloor_scale = 2;
        lm_detectStruct = detection.detection_lm_dualthresh_variable_noisefloor_with_rules(data,params.dualthresh_variable_rule);

    case 6  %variable noise floor
%         noisefloor = round(median(abs(data))+1);
%         noisefloor = median(abs(data));
%         params.dualthresh.threshold_high_uV = (noisefloor+8); %8 uV above resting - presumably resting is 2uV
%         params.dualthresh.threshold_low_uV = (noisefloor+2);
%         params.dualthresh.min_duration_sec = 0.5;
%         params.dualthresh.max_duration_sec = 10.0;
%         params.dualthresh.merge_within_sec = params.merge_within_sec;
        
        params.dualthresh_variable.threshold_high_uV = 8; %8 uV above resting - presumably resting is 2uV
        params.dualthresh_variable.threshold_low_uV = 2;
        params.dualthresh_variable.min_duration_sec = 0.5;
        params.dualthresh_variable.max_duration_sec = 10.0;
        params.dualthresh_variable.merge_within_sec = params.merge_within_sec;
        params.dualthresh_variable.summer_order = 2;
        params.dualthresh_variable.average_power_window_sec = 30;  %calculate average power over consecutive windows of this duration in seconds
        params.dualthresh_variable.summer_order = 2;
        
        lm_detectStruct = detection.detection_lm_dualthresh_variable_noisefloor(data,params.dualthresh_variable);
%         noisefloor
%         min_median
%         params.dualthresh

%         params.dualthresh.merge_within_sec = 0.0;


    case 5  %dual threshold 2
%         noisefloor = round(median(abs(data))+1);
%         noisefloor = median(abs(data));
%          noisefloor = (median(abs(CHANNELS_CONTAINER.getData(channel_indices(1)))));
         %results improve here
         noisefloor = ceil(median(abs(data)));

        params.dualthresh.threshold_high_uV = (noisefloor+8); %8 uV above resting - presumably resting is 2uV
        params.dualthresh.threshold_low_uV = (noisefloor+2);
        params.dualthresh.min_duration_sec = 0.5;
        params.dualthresh.max_duration_sec = 10.0;
        params.dualthresh.merge_within_sec = params.merge_within_sec;
        
        if(params.min_median>0)
            min_median = params.dualthresh.threshold_low_uV-params.min_median;
        else
            min_median = 0;
        end
%         min_median = 0;        
        params.summer_order = 2;
        lm_detectStruct = detection.detection_lm_dualthresh_raw(data,params);
%         noisefloor
%         min_median
%         params.dualthresh

%         params.dualthresh.merge_within_sec = 0.0;

    case 1  %dual threshold
        params.dualthresh.threshold_high_uV = 10; %8 uV above resting - presumably resting is 2uV
        params.dualthresh.threshold_low_uV = 8;  %account for large sum of data
        params.dualthresh.min_duration_sec = 0.5;
        params.dualthresh.max_duration_sec = 10.0;
        params.dualthresh.merge_within_sec = params.merge_within_sec;  %should be 2.0 seconds for the other group
        params.dualthresh.samplerate = samplerate;
        params.dualthresh.summer_order = 2;
        lm_detectStruct = detection.detection_lm_dualthresh_raw(data,params.dualthresh);        
    case 2  %Ferri
        params.ferri.lower_threshold_uV = 2;
        params.ferri.upper_threshold_uV = 9;  %7 uV above resting - presumably resting is 2uV
        params.ferri.min_duration_sec = 0.5;
        params.ferri.max_duration_sec = 10.0;
        params.ferri.filter_hp_freq_Hz = 15;
        params.ferri.filter_order = 100;
        params.ferri.sliding_window_len_sec = 0.5; %the length of the sliding window in seconds that was applied to find
        params.ferri.samplerate = samplerate;
        lm_detectStruct = detection.detection_lm_ferri(data,params.ferri,stageStruct);
    case 3  %Wetter
        params.wetter.truncate_uV = 30; %truncate values to this level
        params.wetter.moving_std_window = 0.16;
        params.wetter.high_std_thresh = 0.6;
        params.wetter.min_burst_dur_sec = 0.4;
        params.wetter.merge_within_sec = 0.5;
        params.wetter.min_duration_sec = 0.5;
        params.wetter.max_duration_sec = 10.0;
        params.wetter.samplerate = samplerate;
        lm_detectStruct = detection.detection_lm_wetter_raw(data,params.wetter);
    case 4  %Tauchmann
        params.tauchmann.threshold_uV = 9;  %7 uV above resting - presumably resting is 2uV
        params.tauchmann.min_duration_sec = 0.52;
        params.tauchmann.max_duration_sec = 10.0;
        params.tauchmann.merge_within_sec = 0.15;
        params.tauchmann.min_auc = 5;
        params.tauchmann.samplerate = samplerate;
        lm_detectStruct = detection.detection_lm_tauchmann_raw(data,params.tauchmann);                
    otherwise
        disp('Not a valid choice');
end

if(isempty(lm_detectStruct.new_events))
    %just return the emptiness
    detectStruct = lm_detectStruct;
else
    %% remove LMs that occur during Stage 7 and before sleep onset
    params.stages2exclude = 7;
    
    %I think this is faster ....
    firstNonWake = 1;
    while((stageStruct.line(firstNonWake)==7||stageStruct.line(firstNonWake)==0) && firstNonWake<=numel(stageStruct.line))
        firstNonWake = firstNonWake+1;
    end
    
    %This is simpler and vectorized, but it actually has three operations that
    %run through the entire MARKING.sev_STAGES.line vector which is not necessary.
    %firstNonWake = find(MARKING.sev_STAGES.line~=0 & MARKING.sev_STAGES.line~=7,1);
    
    %convert these to the epochs the events occur in

    epochs = sample2epoch(lm_detectStruct.new_events,stageStruct.standard_epoch_sec,params.samplerate);
    
    %obtain the stage scores for these epochs
    stages = stageStruct.line(epochs);
    
    if(size(stages,2)==1)
        stages = stages'; %make it a row matrix
    end
    exclude_indices = false(size(epochs,1),2); %have to take into account start and stops being in different epochs
    
    
    for k=1:numel(params.stages2exclude)
        stage2exclude = params.stages2exclude(k);
        exclude_indices = exclude_indices|stages==stage2exclude;
    end
    
    %remove the firstNonWake indices as well here
    exclude_indices = exclude_indices(:,1)|exclude_indices(:,2)|epochs(:,1)<firstNonWake|epochs(:,2)<firstNonWake;
    
    %remove if LM's are not good... based on new criteria...
    
    
    paramStruct = lm_detectStruct.paramStruct;
    if(~isempty(paramStruct))
        fields = fieldnames(paramStruct);
        for k=1:numel(fields)
            paramStruct.(fields{k}) = paramStruct.(fields{k})(~exclude_indices);
        end
    end
    
    lm_events = lm_detectStruct.new_events(~exclude_indices,:);
    
%     lm_events = lm_detectStruct.new_events;
%      paramStruct = lm_detectStruct.paramStruct;
    
    
    %additional complicated criteria to merge events and such after the
    %fact, but which may not be that helpful overall.
%     
%     min_duration = params.dualthresh.min_duration_sec*samplerate;
%     max_duration = params.dualthresh.max_duration_sec*samplerate;
%     merge_distance = round(params.dualthresh.merge_within_sec*samplerate);
%     [lm_events,merged_indices] = CLASS_events.merge_nearby_events(lm_events,merge_distance);
%     if(~isempty(paramStruct))
%         fields = fieldnames(paramStruct);
%         for k=1:numel(fields)
%             paramStruct.(fields{k}) = paramStruct.(fields{k})(~merged_indices);
%         end
%     end
%     duration = (lm_events(:,2)-lm_events(:,1));
%     exclude_indices = duration>max_duration | duration<min_duration;
%     lm_events = lm_events(~exclude_indices,:);
%     if(~isempty(paramStruct))
%         fields = fieldnames(paramStruct);
%         for k=1:numel(fields)
%             paramStruct.(fields{k}) = paramStruct.(fields{k})(~merged_indices);
%         end
%     end
% 

    
    %% Cardiac Analysis
    %         params.filter_order = 10;  %leave this alone - necessary for rr
    %         detector, but will not allow it to be adjusted here
    
    rr_params.filter_order = 10;
    rr_params.samplerate = samplerate;
    hr_detectStruct = detection.detection_rr_simple(channel_cell_data{2},rr_params);
    hr_start_vec = hr_detectStruct.new_events(:,1);
    inst_hr = hr_detectStruct.paramStruct.inst_hr;
    
    num_lm = size(lm_events,1);
    HR_min = zeros(num_lm,1);
    HR_max = zeros(num_lm,1);
    HR_lead = zeros(num_lm,1);
    HR_lag = zeros(num_lm,1);
    
    num_hr_cycles = numel(inst_hr);
    
    %this loop took 1.31 seconds for an RLS case - don't bother optimizing
    for p=1:num_lm
        j = getPrecedingCardiacCycle(lm_events(p,1),hr_start_vec);
        base_hr = inst_hr(j); %baseline heart rate defined as hr immediately preceeding PLM onset/activation
        start_bound = max(j-9,1);
        stop_bound = min(j+10,num_hr_cycles);
        %     normalizedHR = inst_hr(start_bound:stop_bound)-base_hr;
        try
            [HR_min(p), HR_min_ind] = min(inst_hr(start_bound:j)-base_hr); %get the preceding minimum value
            [HR_max(p), HR_max_ind] = max(inst_hr(j+1:stop_bound)-base_hr); %get the ensuing maximum value
            HR_lead(p) = 11-HR_min_ind; % a result of 1 means that the base_hr was lowest
            HR_lag(p) = HR_max_ind;
        catch ME
            disp(ME);
        end
    end
    
    HR_lead = -HR_lead; %negative cycles precede PLM onset
    HR_delta = HR_max-HR_min;
    HR_run = HR_lag-HR_lead;
    HR_slope = HR_delta./HR_run;
    
    %tack on the additional timelocked HR parameters that we found
    paramStruct.HR_min = HR_min;
    paramStruct.HR_max = HR_max;
    paramStruct.HR_lead = HR_lead;
    paramStruct.HR_lag = HR_lag;
    paramStruct.HR_delta = HR_delta;
    paramStruct.HR_run = HR_run;
    paramStruct.HR_slope = HR_slope;
    
    %% remove nonphysiologically based LMs as necesseary...
    
    %clean up based on physiology
    
%     if(params.lm_hr_physiology_matching)
%         exclude_indices = paramStruct.HR_slope<params.HR_ratio_threshold; %not physiologically based
%         
%         fields = fieldnames(paramStruct);
%         for k=1:numel(fields)
%             paramStruct.(fields{k}) = paramStruct.(fields{k})(~exclude_indices);
%         end
%         
%         lm_events = lm_events(~exclude_indices,:);
%         
%     end
%     
    
    detectStruct.new_data = lm_detectStruct.new_data;
    detectStruct.new_events = lm_events;
    
    detectStruct.paramStruct = paramStruct;
    
    %apply PLM rules now - handle this post hoc since various rules can be
    %applied to filter out unwanted LM from PLM inclusion depending on the
    %analysis
%     detectStruct = calculatePLMstruct(detectStruct,samplerate);
    
end

function p = getPrecedingCardiacCycle(plm_sample, hr_events)
%plm_sample is the index of a digital time signal
%hr_events is a vector of digital time starting events
%p is the index of hr_events whose value immediately precedes plm_sample
p = find(hr_events<plm_sample,1,'last');

