function detectStruct = detection_plm_dualthresh_anc_and_hr(channel_indices, optional_params)
% detects PLM using dualthreshold method with adaptive
% noise cancelling of ECG channel. 
%
% The algorithm is as follows
% (1) Adaptive noise cancel ECG out of Leg EMG
% (2) Smooth using 0.5 second moving averager (MA filter)
% (3) Run a 2-sample summer to increase SNR
% (4) Dual threshold at 10uV and 8uV
% (5) Prune using LM duration criteria
% (6) Classify PLM using AASM 2007 criteria
% (7) obtain HR data as described here:
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
% optional parameters are included for plm_threshold function and loaded
% from .plist file otherwise
%
% Written by Hyatt Moore IV, 6/8/2012

global CHANNELS_CONTAINER;
sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));

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
        params.threshold_high_uV = 10; 
        params.threshold_low_uV = 8;  %8 uV above resting - presumably resting is 2uV
        params.min_duration_sec = 0.5;
        params.max_duration_sec = 10.0;
        params.HR_seconds_after = 10; %number of seconds to look at HR variability after LM hit
        params.HR_seconds_before = 10; %number of seconds to look at before LM hit
        params.HR_ratio_threshold = 0.3; %percent different between before and after HR measures...
   
%         params.filter_order = 10;  %leave this alone - necessary for rr
%         detector, but will not allow it to be adjusted here
        plist.saveXMLPlist(pfile,params);
    end
end
params.merge_within_sec = 2;

%use other detection methods first...

%1. adaptively cancel noise from ECG using recursive least squares method
clean_data = abs(filter.anc_rls(channel_indices(1),channel_indices(2)));

%2 smooth the data with moving averager
ma.params.order = ceil(params.min_duration_sec*sample_rate);
ma.params.rms = 0;
clean_data = filter.filter_ma(clean_data,ma.params);

%3 increase SNR using 2 point moving integrator
integrator = ma;
integrator.params.order = 2;
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
lm_events = lm_detectStruct.new_events;
if(~isempty(lm_events))
    clean_indices = (lm_events(:,2)-lm_events(:,1))<max_duration;
    lm_detectStruct.new_events = lm_detectStruct.new_events(clean_indices,:);

%     fnames = fieldnames(lm_detectStruct.paramStruct);
%     for f = 1:numel(fnames)
%        lm_detectStruct.paramStruct.(fnames{f}) = lm_detectStruct.paramStruct.(fnames{f})(clean_indices); 
%     end

end;


paramStruct = lm_detectStruct.paramStruct;
plm_events = lm_detectStruct.new_events;

%now apply cardiac analysis
hr_detectStruct = detection.detection_rr_simple(channel_indices(2));
hr_start_vec = hr_detectStruct.new_events(:,1);
inst_hr = hr_detectStruct.paramStruct.inst_hr;

num_plm = size(plm_events,1);
HR_min = zeros(num_plm,1);
HR_max = zeros(num_plm,1);
HR_lead = zeros(num_plm,1);
HR_lag = zeros(num_plm,1);

num_hr_cycles = numel(inst_hr);

%this loop took 1.31 seconds for an RLS case - don't bother optimizing
for p=1:num_plm
    j = getPrecedingCardiacCycle(plm_events(p,1),hr_start_vec);
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


detectStruct.new_data = lm_detectStruct.new_data;
detectStruct.new_events = lm_detectStruct.new_events;

detectStruct.paramStruct = paramStruct;

%apply PLM rules now
detectStruct = calculatePLM(detectStruct,sample_rate);

function p = getPrecedingCardiacCycle(plm_sample, hr_events)
%plm_sample is the index of a digital time signal
%hr_events is a vector of digital time starting events
%p is the index of hr_events whose value immediately precedes plm_sample
p = find(hr_events<plm_sample,1,'last');

function plm_detectStruct = calculatePLM(lm_detectStruct, sample_rate)
plm_detectStruct = lm_detectStruct;

LM_evts = lm_detectStruct.new_events;
if(numel(LM_evts)>1)

    params.PLM_AASM_min_interval_sec = 5;
    params.PLM_max_interval_sec = 90;
    params.PLM_min_LM_req = 4; %need 3 intervals with the interval range (4 LM in series)
    params.merge_LM_within_sec = 0.5;  %interval 2 in the paper
    params.PLM_ferri_min_inter_lm_dur_sec = 10;

    %create a holder for each possible PLM event
    PLM_candidates = false(size(LM_evts,1),1);
    PLM_series = zeros(size(PLM_candidates));  %holds the PLM mini series count, starting at one.  The first 4+ LM that meet criteria are labeled as PLM; they are PLM_series 1; the next 4+ are PLM_series 2
    meet_ferri_inter_lm_duration_criteria = false(size(LM_evts,1),1);  %this variable assists in calculating the periodicity index defined by Ferri and should be set to true when all PLMs in a series
                                                                % have an interval greater than 10-s 
    %this is defined for onset to onset interval between LM
    all_inter_lm_intervals = [diff(LM_evts(:,1));0]; %intervals between LM onsets - used for periodicity
    
    %should already be handled ealier
    %this is defined as interval between the end of one LM and the
    %beginning of the next (or equally, as coded here, the interval from
    %the start of one lm and the beginning of the previous one)
    % offset2onset_interval = LM_evts(2:end,1)-LM_evts(1:end-1,2); %interval between offset
    % and next onset - used in merge_nearby_events method above
    
    %% Identify candidate PLMs as LMs with consecutive onsets between 5-90 seconds
    PLM_onset2onset_AASM_range = [params.PLM_AASM_min_interval_sec params.PLM_max_interval_sec]*sample_rate;
    PLM_interval_candidates = all_inter_lm_intervals>=PLM_onset2onset_AASM_range(1)&all_inter_lm_intervals<=PLM_onset2onset_AASM_range(2);
    
    PLM_onset2onset_ferri_range = [params.PLM_ferri_min_inter_lm_dur_sec params.PLM_max_interval_sec]*sample_rate;
    ferri_interval_candidates = all_inter_lm_intervals>=PLM_onset2onset_ferri_range(1)&all_inter_lm_intervals<=PLM_onset2onset_ferri_range(2);
    
    %there is one less interval than the number of lm required (intervals
    %go inbetween)
    PLM_min_LM_intervals = params.PLM_min_LM_req -1;

    in_PLM_series_flag = false;  %use this variable to keep track of when you are in a PLM series, so that PLMs that are more than 4 LM's long do not start show a higher PLM_series value
    num_series = 0;
    for k = 1:numel(all_inter_lm_intervals)-PLM_min_LM_intervals+1
        if(all(PLM_interval_candidates(k:k+PLM_min_LM_intervals-1)))
            if(~in_PLM_series_flag)
                num_series = num_series+1;
                in_PLM_series_flag = true;                
            end
            PLM_candidates(k:k+PLM_min_LM_intervals)=true;
            PLM_series(k:k+PLM_min_LM_intervals)=num_series;
                        
            %this if statmement is used instead of the one below it so that
            %not as much time is spent computing all of them as done
            %when only a subset may need to be calculated (i.e. those that
            %meet the firs,t all_inter_lm_intervals, criteria
            if(all(ferri_interval_candidates(k:k+PLM_min_LM_intervals-1)))
                meet_ferri_inter_lm_duration_criteria(k:k+PLM_min_LM_intervals)=true;
            end
        else
            in_PLM_series_flag = false; %the PLM series ended;
        end
    end
    
    plm_detectStruct.paramStruct.series = PLM_series;    
    plm_detectStruct.paramStruct.meet_ferri_inter_lm_duration_criteria = meet_ferri_inter_lm_duration_criteria;
    plm_detectStruct.paramStruct.meet_AASM_PLM_criteria = PLM_candidates;
    plm_detectStruct.paramStruct.onset2onset_sec = all_inter_lm_intervals;
    
%     fnames = fieldnames(plm_detectStruct.paramStruct);
%     for f = 1:numel(fnames)
%        plm_detectStruct.paramStruct.(fnames{f}) = plm_detectStruct.paramStruct.(fnames{f})(PLM_candidates); 
%     end
  
    %keep all LM's for now still
%     plm_detectStruct.new_events = plm_detectStruct.new_events(PLM_candidates,:);
   
end