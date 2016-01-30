function detectStruct = detection_plm_wasm(source_indices)
%    source_indices(1) should be the LAT/RAT leg EMG channel
%    source_indices(2) should be the the EEG channel
%    source_indices(3) should be the nasal pressure channel
%  The WASM PLM protocol states: 
% "Calibration used in the past based on definitions of maximum  
% dorsiflexion at the ankle withuot resistance, was considered too vague
% and susceptible to technician differences to be useful. It was
% therefore  unanimously decided to use the absolute increase in
% microvolts for  detecting a significant event...Aside from meeting the
% criteria as   defined below there are no magnitude requirements." 

% WASM criterial
% Definition of Leg Movements (LM):
%  Duration: 0.5 to 10.0 seconds (and up to 15.0 seconds for reasearch)
%  Amplitude: Use absolute microvolt threshold (?)
% Frequency: Need greater than 4 seconds to distinguish separate LM
%     Movements within 4 seconds of each other, are counted as  one movement.
%     Movements which are separated by at least 4 seconds  are counted as separate movements.  
%     Movements that occur during wakefulness are not counted. 
% LM AROUSAL (LMA):  
% "An arousal event and movement event are considered associated with each
% other when there is less than .5s between the end of one event and the
% onset of the other event regardless of which is first."  
% Source_indices is a vector of class channel indices
global CHANNELS_CONTAINER;
global STAGES;
global DEFAULTS;

stage_7_epochs = find(STAGES.line==7);
stage_0_epochs = find(STAGES.line==0);

% stage_7_epochs = 1;
% stage_0_epochs = 1;
% stage_7_indices = (stage_7_epochs-1)*DEFAULTS.fs*DEFAULTS.standard_epoch_sec+1:(stage_7_epcohs)*DEFAULTS.fs*DEFAULTS.standard_epoch_sec;


LEG_channel = CHANNELS_CONTAINER.cell_of_channels{source_indices(1)};
NPP_channel = CHANNELS_CONTAINER.cell_of_channels{source_indices(3)}; %Nasal Pressure Plug (NPP)
EEG_channel = CHANNELS_CONTAINER.cell_of_channels{source_indices(2)};

%% 1. Obtain candidate leg movements
[LM_data, LM_evts] = detection.detection_lm_wasm(source_indices(1));

%% 2. Discard leg movements that are within 0.5 seconds of respiratory arousal
[hyp_arousal_data, hyp_with_arousal_evts] = detection.detection_arousals_after_hypopnea(source_indices(2:3));
resp_overlap_range_sec = [-0.5 1];
resp_overlap_range = resp_overlap_range_sec*NPP_channel.sample_rate;

arousal_evts = hyp_with_arousal_evts+repmat(resp_overlap_range,size(hyp_with_arousal_evts,1),1);
PLM_evts = zeros(size(LM_evts));
num_evts = 0;

%don't want to include events that occur during stage 7...
LM_evts_epoch = sample2epoch(LM_evts,DEFAULTS.standard_epoch_sec,DEFAULTS.fs);

for k = 1:size(LM_evts,1)
    if(~any(LM_evts_epoch(k,1)==stage_7_epochs)&&~any(LM_evts_epoch(k,2)==stage_7_epochs))
         if(~any(LM_evts_epoch(k,1)==stage_0_epochs)&&~any(LM_evts_epoch(k,2)==stage_0_epochs))
            %this part can definitely be optimized for speed...
            if(~any((LM_evts(k,1)>arousal_evts(:,1)& LM_evts(k,1)<arousal_evts(:,2))|...
                    (LM_evts(k,2)>arousal_evts(:,1)& LM_evts(k,2)<arousal_evts(:,2))))
                num_evts = num_evts+1;
                PLM_evts(num_evts,:)=LM_evts(k,:);
            end
         end
    end
end

%just grab the non-zero PLM data
PLM_evts = PLM_evts(1:num_evts,:);

%% 3. Identify candidate PLMs as LMs with consecutive onsets between 5-90 seconds
if(~isempty(PLM_evts))
    PLM_onset2onset_range_sec = [5 90];
    PLM_onset2onset_range = PLM_onset2onset_range_sec*LEG_channel.sample_rate;
    PLM_candidates = cell(size(PLM_evts,1),1);
    candidate_count = zeros(size(PLM_candidates));
    
    %initialize the first one...
    cur_candidate = 1;
    candidate_count(1) = 1;
    PLM_candidates{1} = PLM_evts(1,:);
    
    for k = 2:size(PLM_evts,1)
        period = PLM_evts(k,1)-PLM_evts(k-1,1);
        if(~(period>PLM_onset2onset_range(1) && period<PLM_onset2onset_range(2)))
            cur_candidate = cur_candidate+1;         
        end
        candidate_count(cur_candidate) = candidate_count(cur_candidate)+1;
        PLM_candidates{cur_candidate}(candidate_count(cur_candidate),:) = PLM_evts(k,:);
        
    end
    PLM_candidates = PLM_candidates(1:cur_candidate);
    candidate_count = candidate_count(1:cur_candidate);
    
    PLM_count_req = 4;
    PLM_evts_cell = PLM_candidates(candidate_count>=PLM_count_req);
    disp(['periodicity index = ',num2str(numel(PLM_evts_cell)/cur_candidate)]);
    detectStruct.new_events = cell2mat(PLM_evts_cell);
        
else
    detectStruct.new_events = [];
end
detectStruct.paramStruct = [];
detectStruct.new_data = LEG_channel.raw_data;