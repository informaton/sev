function evtStruct = detection_plm_best(PatStudyKey, remove_artifact_flag, detector_query_str,artifact_query_str)
% function evtStruct = plm_calculator(PatStudyKey, remove_artifact_flag)
% This function looks up LMs and SCO hypopnea/apneas from Events_Ttable 
% using PatStudyKey (string), and removes any LMs with +/-3.0 second overlap
% of respiratory events (determined by Wisconsin Cohort manually SCO
% scoring) if remove_artifact_flag is true;
% detectorID_LM is the detectorID of the LM events to use from Events_T
% detectorConfig_LM is the detection configuration to use (if included)
% evtStruct is output structure with the following fields:
% Start_sample
% Stop_sample
% Duration_seconds
% Epoch
% Stage
% series
% meet_ferri_inter_lm_duration_criteria
% meet_AASM_PLM_criteria;
% area_under_curve

sample_rate = 100;
params.PLM_AASM_min_interval_sec = 5;  
params.PLM_max_interval_sec = 90;
params.PLM_min_LM_req = 4; %need 3 intervals with the interval range (4 LM in series)
params.merge_LM_within_sec = 0.5;  %interval 2 in the paper
params.PLM_ferri_min_inter_lm_dur_sec = 10; 

% detectorIDfmt = repmat(' and detectorID=%d',1,numel(detectorID_LM));
% detectorIDstr = sprintf(detectorIDfmt,detectorID);
% 
% if(nargin==4 && ~isempty(detectorConfigID_LM))
%     detectorConfigIDstr = ['and detectorConfigID=',num2str(detectorConfigID_LM(1))];
% else
%     detectorConfigIDstr = '';
% end;
       

%% 1. Obtain candidate leg movements - LM in stage 0 and stage 7 have been
q = mym(['select start_sample, stop_sample, Duration_seconds, Epoch, Stage, Params from Events_T where patstudykey=',PatStudyKey,' and (stage!="0" and stage!="7") and ',detector_query_str]);
% [start_sample, stop_sample, Duration_seconds, Epoch, Stage] 
LM_evts = [q.start_sample, q.stop_sample];


%% 2. Ferri does not discard leg movements that are within 0.5 seconds of respiratory arousal
% but we will here
if(remove_artifact_flag)

    %get and combine all artifact events into a single 2 column matrix
    qart = mym(['SELECT start_sample AS start, stop_sample AS stop FROM Events_T where (Stage=''1'' OR Stage=''2'' OR Stage=''3'' OR Stage=''4'' OR Stage=''5'') AND PatStudyKey=',PatStudyKey,' and ',artifact_query_str,' order by start_sample']);
    mat_Artifact = [qart.start,qart.stop];
    
    %sort event matrix in ascending order
    [~,sorted_ind] = sort(mat_Artifact(:,1));
    mat_Artifact = mat_Artifact(sorted_ind,:);
    
    % any overlap within  +/- 3.0 seconds of an apneic event should be removed
    exclude_respiratory_distance_sec = 3.0;
    plus_minus_overlap = exclude_respiratory_distance_sec*sample_rate;  %remove any with overlap
    mat_Artifact = [mat_Artifact(:,1)-plus_minus_overlap, mat_Artifact(:,2)+plus_minus_overlap];
    
    %check for artifact overlap
    artifact_threshold = 0.00001;  %~any overlap
    [~,~,~,interaction_matrix_predictor_vs_artifact] = getEventspace(LM_evts,mat_Artifact);
    hold_ind = sum(interaction_matrix_predictor_vs_artifact,2)<artifact_threshold;
else
    hold_ind = true(size(LM_evts,1),1); 
end

try
    LM_evts = LM_evts(hold_ind,:);
catch ME
    disp(ME);
end

% evtStruct.DetectorID = DetectorID(hold_ind);
% evtStruct.DetectorConfigID = DetectorConfigID(hold_ind);

evtStruct.Start_sample = q.start_sample(hold_ind);
evtStruct.Stop_sample = q.stop_sample(hold_ind);
evtStruct.Duration_seconds = q.Duration_seconds(hold_ind);
evtStruct.Epoch = q.Epoch(hold_ind);
evtStruct.Stage = q.Stage(hold_ind);
AUCMat = cell2mat(q.Params);
if(isempty(AUCMat))
    evtStruct.area_under_curve = zeros(sum(hold_ind),1);
else
    AUC = cell(size(AUCMat));
    [AUC{:}] = AUCMat.AUC;
    evtStruct.area_under_curve = cell2mat(AUC(hold_ind));
end
% evtStruct.area_under_curve = zeros(size(hold_ind)); %area_under_curve(hold_ind);

%3.  merge movements within <0.5 seconds of separation - Ferri requires 0.5
%separation - this is handled in the Ferri LM detector 

if(numel(LM_evts)>1)

    %create a holder for each possible PLM event
    PLM_candidates = false(size(LM_evts,1),1);
    PLM_series = zeros(size(PLM_candidates));  %holds the PLM mini series count, starting at one.  The first 4+ LM that meet criteria are labeled as PLM; they are PLM_series 1; the next 4+ are PLM_series 2
    meet_ferri_inter_lm_duration_criteria = false(size(LM_evts,1),1);  %this variable assists in calculating the periodicity index defined by Ferri and should be set to true when all PLMs in a series
                                                                % have an interval greater than 10-s 
%     meet_AASM_PLM_criteria = false(size(LM_evts,1)); %set to true for LMs that make up a PLM for AASM criteria (will have a miniseries group number)

    %this is defined for onset to onset interval between LM
    all_inter_lm_intervals = [diff(LM_evts(:,1));0]; %intervals between LM onsets - used for periodicity
    
    %should already be handled ealier
    %this is defined as interval between the end of one LM and the
    %beginning of the next (or equally, as coded here, the interval from
    %the start of one lm and the beginning of the previous one)
    % offset2onset_interval = LM_evts(2:end,1)-LM_evts(1:end-1,2); %interval between offset
    % and next onset - used in merge_nearby_events method above
    
    %% 3. Identify candidate PLMs as LMs with consecutive onsets between 5-90 seconds
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
%             meet_AASM_PLM_criteria(k:k+PLM_min_LM_intervals)=true;
                        
            %this if statmement is used instead of the one below it so that
            %not as much time is spent computing all of them as in line 76
            %when only a subset may need to be calculated (i.e. those that
            %meet the firs,t all_inter_lm_intervals, criteria
            if(all(ferri_interval_candidates(k:k+PLM_min_LM_intervals-1)))
                meet_ferri_inter_lm_duration_criteria(k:k+PLM_min_LM_intervals)=true;
            end
        else
            in_PLM_series_flag = false; %the PLM series ended;
        end
    end
    
    evtStruct.series = PLM_series;    
    evtStruct.meet_ferri_inter_lm_duration_criteria = meet_ferri_inter_lm_duration_criteria;
    evtStruct.meet_AASM_PLM_criteria = PLM_candidates;
    evtStruct.onset2onset_sec = all_inter_lm_intervals;
    
else
    evtStruct.Start_sample = [];
end