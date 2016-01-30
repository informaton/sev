function detectStruct = detection_ocular_movement(source_indices)
global CHANNELS_CONTAINER;
% global DETECTION_PARAMETERS;

OCULAR1 = CHANNELS_CONTAINER.cell_of_channels{source_indices(1)};
OCULAR2 = CHANNELS_CONTAINER.cell_of_channels{source_indices(2)};

abs_of_eye_diff = abs(OCULAR1.raw_data-OCULAR2.raw_data);
mean_of_eye_movements = mean(abs_of_eye_diff);
threshold_of_eye_movements = mean_of_eye_movements*2;
% threshold_of_eye_movements = 30*2; %30 uV was limit in paper "precise measures of REM"

first_pass = thresholdcrossings(abs_of_eye_diff, threshold_of_eye_movements);


%once the eye movements have been found, make a second pass to pull them
%together in a useful way.  The output from processArtifacts is actually a\
distanceApart_sec = 0.01;

merge_distance = distanceApart_sec*OCULAR1.sample_rate;
ocular_artifacts = CLASS_events.merge_nearby_events(first_pass, merge_distance);

% additional_buffer_sec = 0.1;
% ocular_artifacts = merge_events(first_pass_eye_movements,...
%     OCULAR1.sample_rate,distanceApart_sec,additional_buffer_sec);

detectStruct.new_data = abs_of_eye_diff;
detectStruct.new_events = ocular_artifacts;
detectStruct.paramStruct = [];


% ARTIFACT_OCULAR.reference_line_offsets = [mean_of_eye_movements;threshold_of_eye_movements];
% 
% ARTIFACT_OCULAR.update_event_object(events_class(ARTIFACT_OCULAR.EDF_index,ARTIFACT_OCULAR.EDF_label,...
%     ARTIFACT_OCULAR.sample_rate,ocular_artifacts,{'SEV.OcularMovement.A'}));
%             
% set(ARTIFACT_OCULAR.reference_line_handles(1),'linestyle','-');
% set(ARTIFACT_OCULAR.reference_line_handles(2),'linestyle','-');    
% set(ARTIFACT_OCULAR.reference_text_handles(1),'string',['Mean =',num2str(ARTIFACT_OCULAR.reference_line_offsets(1)),' uV']);
% set(ARTIFACT_OCULAR.reference_text_handles(2),'string',['Threshold = ',num2str(ARTIFACT_OCULAR.reference_line_offsets(2)),' uV']);
% end

%This would benefit from having
%a minimum detection distance (0.5 secondsfor instance)
%setting the threshold /adjust it by a scalar value of some sort...
%adjusting distance to merge nearby (within some time frame?)
