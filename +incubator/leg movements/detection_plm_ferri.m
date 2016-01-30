function detectStruct = detection_plm_ferri(source_index,optional_params)
%  source_index should be the LAT/RAT leg EMG channel
%PLM detector based on Ferri's paper - see LM detector by Ferri for further
%details on LM criteria
%
% PLMI = #LM intevals that meet the PLM requirement (followed and preceded
% by LM with interval [5,90] range divided by all LM intervals (# of LMs-1)
global CHANNELS_CONTAINER;

%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_plm_ferri.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.PLM_min_interval_sec = 5; 
        params.PLM_max_interval_sec = 90;
        params.PLM_min_LM_req = 4; %need 3 intervals with the interval range (4 LM in series)
        params.merge_LM_within_sec = 0.5;
        plist.saveXMLPlist(pfile,params);
    end
end

params.PLM_offset2onset_min_dur_sec = 10; 
params.PLM_offset2onset_max_dur_sec = 90; 

LEG_channel = CHANNELS_CONTAINER.cell_of_channels{source_index};

%% 1. Obtain candidate leg movements - LM in stage 0 and stage 7 have been
% excluded
LM_struct = detection.detection_lm_ferri(source_index);

LM_evts = LM_struct.new_events;


%% 2. Ferri does not discard leg movements that are within 0.5 seconds of respiratory arousal
% but perhaps we should????

%3.  merge movements within <0.5 seconds of separation - Ferri requires 0.5
%separation - this is handled in the Ferri LM detector 


if(numel(LM_evts)>1)

    %create a holder for each possible PLM event
    PLM_candidates = false(size(LM_evts,1),1);
    PLM_series = zeros(size(PLM_candidates));  %holds the PLM mini series count, starting at one.  The first 4+ LM that meet criteria are labeled as PLM; they are PLM_series 1; the next 4+ are PLM_series 2
    meet_interval2_duration_criteria = false(size(LM_evts,1),1);  %this variable assists in calculating the periodicity index defined by Ferri and should be set to true when all PLMs in a series
                                                                % have an interval greater than 10-s 
    
    %this is defined for offset to offset interval between LM
    interval1 = diff(LM_evts(:,1)); %intervals between LM onsets - used for periodicity
    
    %this is defined as interval between the end of one LM and the
    %beginning of the next (or equally, as coded here, the interval from
    %the start of one lm and the beginning of the previous one)
    interval2 = LM_evts(2:end,1)-LM_evts(1:end-1,2); %interval between offset
    % and next onset - used in merge_nearby_events method above
    
    %% 3. Identify candidate PLMs as LMs with consecutive onsets between 5-90 seconds
    PLM_onset2onset_range = [params.PLM_min_interval_sec params.PLM_max_interval_sec]*LEG_channel.sample_rate;
    LM_interval_candidates = interval1>=PLM_onset2onset_range(1)&interval1<=PLM_onset2onset_range(2);
    
    PLM_offset2onset_range = [params.PLM_offset2onset_min_dur_sec params.PLM_offset2onset_max_dur_sec]*LEG_channel.sample_rate;
%     LM_interval2_candidates = interval12>=PLM_offset2onset_range(1)&interval2<=PLM_offset2onset_range(2);
    
    %there is one less interval than the number of lm required (intervals
    %go inbetween)
    PLM_min_LM_intervals = params.PLM_min_LM_req -1;

    in_PLM_series_flag = false;  %use this variable to keep track of when you are in a PLM series, so that PLMs that are more than 4 LM's long do not start show a higher PLM_series value
    num_series = 0;
    for k = 1:numel(interval1)-PLM_min_LM_intervals+1
        if(all(LM_interval_candidates(k:k+PLM_min_LM_intervals-1)))
            if(~in_PLM_series_flag)
                num_series = num_series+1;
                in_PLM_series_flag = true;                
            end
            PLM_candidates(k:k+PLM_min_LM_intervals)=true;
            PLM_series(k:k+PLM_min_LM_intervals)=num_series;
            %this if statmement is used instead of the one below it so that
            %not as much time is spent computing all of them as in line 76
            %when only a subset may need to be calculated (i.e. those that
            %meet the firs,t interval1, criteria
            if(all(interval2(k:k+PLM_min_LM_intervals-1)>=PLM_offset2onset_range(1)& interval2(k:k+PLM_min_LM_intervals-1)<=PLM_offset2onset_range(2)))
%             if(all(LM_interval2_candidates(k:k+PLM_min_LM_intervals-1)))
                meet_interval2_duration_criteria(k:k+PLM_min_LM_intervals)=true;
            end
        else
            in_PLM_series_flag = false; %the PLM series ended;
        end
    end
    
%     PLM_events = LM_evts(PLM_candidates,:);
%     paramStruct.series = PLM_series(PLM_candidates);
%     paramStruct.meets_interval2_duration_criteria = meet_interval2_duration_criteria(PLM_candidates);
%     paramStruct.area_under_curve = LM_struct.paramStruct.AUC(PLM_candidates);
% %     paramStruct.interval1_sec = interval1(PLM_candidates);
% %     paramStruct.interval2_sec = interval2(PLM_candidates);

%retain all of them to make it easier to handle later on in the database
%post processing and trying to figure out LMs versus PLMs and they don't
%always match up.
    PLM_events = LM_evts;
    paramStruct.series = PLM_series;
    paramStruct.meets_interval2_duration_criteria = meet_interval2_duration_criteria;
    paramStruct.area_under_curve = LM_struct.paramStruct.AUC;
%     paramStruct.interval1_sec = interval1;
%     paramStruct.interval2_sec = interval2;

    new_events = PLM_events;
    
else
    paramStruct = [];
    new_events = [];
end
detectStruct.new_events = new_events;
detectStruct.paramStruct = paramStruct;
detectStruct.new_data = LEG_channel.raw_data;