function plm_detectStruct = calculatePLMstruct(lm_detectStruct, sample_rate)
%calculate PLM parameters from the given LM detection structure
%LM_detectStruct has the following fields

% Hyatt Moore IV
% < June, 2013
%
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
                meet_ferri_inter_lm_duration_criteria(k:k+PLM_min_LM_intervals-1)=true;
            end
        else
            in_PLM_series_flag = false; %the PLM series ended;
        end
    end
    
%     plm_detectStruct.PLM_metric.PLMI = PLM_onset2onset_AASM_range;
    
    plm_detectStruct.paramStruct.series = PLM_series;    
    plm_detectStruct.paramStruct.meet_ferri_inter_lm_duration_criteria = meet_ferri_inter_lm_duration_criteria;
    plm_detectStruct.paramStruct.meet_AASM_PLM_criteria = PLM_candidates;
    plm_detectStruct.paramStruct.onset2onset_sec = all_inter_lm_intervals/sample_rate;
    
%     fnames = fieldnames(plm_detectStruct.paramStruct);
%     for f = 1:numel(fnames)
%        plm_detectStruct.paramStruct.(fnames{f}) = plm_detectStruct.paramStruct.(fnames{f})(PLM_candidates); 
%     end
  
    %keep all LM's for now still
%     plm_detectStruct.new_events = plm_detectStruct.new_events(PLM_candidates,:);
%    sum(plm_detectStruct.paramStruct.meet_AASM_PLM_criteria)
end