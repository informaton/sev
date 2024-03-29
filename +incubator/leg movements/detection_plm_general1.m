function detectStruct = detection_plm_general(channel_indices, optional_params)
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

global CHANNELS_CONTAINER;
global DEFAULTS;
global STAGES;

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
        params.detector = 1;  %1 = dual threshold
                              %2 = Ferri
                              %3 = Wester
                              %4 = Tauchman                              
        params.filter_with_anc = 0; %adaptively filter ECG (0 = no; 1 = yes)
        params.high_pass_filter_hz = 0; %set this if you want to high pass filter
        params.lm_hr_physiology_matching = 0; %if 1, then remove lm's without a cardiac acceleration associated with it
        
        params.HR_seconds_after = 10; %number of seconds to look at HR variability after LM hit
        params.HR_seconds_before = 10; %number of seconds to look at before LM hit
        params.HR_ratio_threshold = 0.5; %percent different between before and after HR measures...

        plist.saveXMLPlist(pfile,params);
    end
end


%adaptive noise cancel if selected
if(params.filter_with_anc)
    %1. adaptively cancel noise from ECG using recursive least squares method
    data = filter.anc_rls(channel_indices(1),channel_indices(2));
else
    data = CHANNELS_CONTAINER.getData(channel_indices(1));
end

%high pass if selected
if(params.high_pass_filter_hz~=0)
    params.hp.order = sample_rate;
    params.hp.sample_rate = sample_rate;
    params.hp.freq_hz = params.high_pass_filter_hz;
    data = filter.fir_hp(data,params.hp);
end

switch params.detector
    case 1  %dual threshold
        params.dualthresh.threshold_high_uV = 10; %8 uV above resting - presumably resting is 2uV
        params.dualthresh.threshold_low_uV = 8;  
        params.dualthresh.min_duration_sec = 0.5;
        params.dualthresh.max_duration_sec = 10.0;
        params.dualthresh.merge_within_sec = 2;
        params.dualthresh.sample_rate = sample_rate;
        lm_detectStruct = detection.detection_lm_dualthresh_raw(data,params.dualthresh);
    case 2  %Ferri
        params.ferri.lower_threshold_uV = 2;
        params.ferri.upper_threshold_uV = 9;  %7 uV above resting - presumably resting is 2uV
        params.ferri.min_duration_sec = 0.5;
        params.ferri.max_duration_sec = 10.0;
        params.ferri.sliding_window_len_sec = 0.5; %the length of the sliding window in seconds that was applied to find
        params.ferri.sample_rate = sample_rate;
        lm_detectStruct = detection.detection_lm_ferri_raw(data,params.ferri);
    case 3  %Westtin
    case 4  %Tauchmann
        params.tauchmann.threshold_uV = 9;  %7 uV above resting - presumably resting is 2uV
        params.tauchmann.min_duration_sec = 0.5;
        params.tauchmann.max_duration_sec = 10.0;
        params.tauchmann.merge_within_sec = 0.15;
        params.tauchmann.min_auc = 5;
        params.tauchmann.sample_rate = sample_rate;
        lm_detectStruct = detection.detection_lm_tauchmann_raw(data,params.tauchmann);        
    otherwise
        disp('Not a valid choice');
end

%% remove LMs that occur during Stage 7 and before sleep onset
params.stages2exclude = 7;

%I think this is faster ....
firstNonWake = 1;
while((STAGES.line(firstNonWake)==7||STAGES.line(firstNonWake)==0) && firstNonWake<=numel(STAGES.line))
    firstNonWake = firstNonWake+1;
end

%This is simpler and vectorized, but it actually has three operations that
%run through the entire STAGES.line vector which is not necessary.
%firstNonWake = find(STAGES.line~=0 & STAGES.line~=7,1);

%convert these to the epochs the events occur in
epochs = sample2epoch(lm_detectStruct.new_events,DEFAULTS.standard_epoch_sec,sample_rate);

%obtain the stage scores for these epochs
stages = STAGES.line(epochs);

exclude_indices = false(size(epochs,1),2); %have to take into account start and stops being in different epochs

for k=1:numel(params.stages2exclude)
    stage2exclude = params.stages2exclude(k);
    exclude_indices = exclude_indices|stages==stage2exclude;
end

%remove the firstNonWake indices as well here
exclude_indices = exclude_indices(:,1)|exclude_indices(:,2)|epochs(:,1)<firstNonWake|epochs(:,2)<firstNonWake;

paramStruct = lm_detectStruct.paramStruct;
if(~isempty(paramStruct))
    fields = fieldnames(paramStruct);
    for k=1:numel(fields)
        paramStruct.(fields{k}) = paramStruct.(fields{k})(~exclude_indices);
    end
end

lm_events = lm_detectStruct.new_events(~exclude_indices,:);



%% Cardiac Analysis
%         params.filter_order = 10;  %leave this alone - necessary for rr
%         detector, but will not allow it to be adjusted here

hr_detectStruct = detection.detection_rr_simple(channel_indices(2));
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
if(params.lm_hr_physiology_matching)
    exclude_indices = paramStruct.HR_slope<params.HR_ratio_threshold; %not physiologically based
    
    fields = fieldnames(paramStruct);
    for k=1:numel(fields)
        paramStruct.(fields{k}) = paramStruct.(fields{k})(~exclude_indices);
    end
    
    lm_events = lm_events(~exclude_indices,:);

end


detectStruct.new_data = lm_detectStruct.new_data;
detectStruct.new_events = lm_events;

detectStruct.paramStruct = paramStruct;

%apply PLM rules now
detectStruct = calculatePLMstruct(detectStruct,sample_rate);

function p = getPrecedingCardiacCycle(plm_sample, hr_events)
%plm_sample is the index of a digital time signal
%hr_events is a vector of digital time starting events
%p is the index of hr_events whose value immediately precedes plm_sample
p = find(hr_events<plm_sample,1,'last');

