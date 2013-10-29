function detectStruct = detection_ocular_movement_v2(channel_cell_data,varargin)
%differs from detection_ocular_movement functinon in that it takes into
%account when only one eye is "popping" while the other remains still -
%likely due to artifact from electrode placement.


%written by Hyatt Moore
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input


if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
%         params.operation = 'mean';
        params.sum_threshold_scale_factor = 3;
        params.diff_threshold_scale_factor = 3;
        params.max_merge_time_sec = 0.1;
        plist.saveXMLPlist(pfile,params);
    end
end
detectStruct.paramStruct = [];

OCULAR1.data = channel_cell_data{1};
OCULAR2.data = channel_cell_data{2};
samplerate = params.samplerate;
abs_of_eye_diff = abs(OCULAR1.data-OCULAR2.data);
abs_of_eye_sum = abs(OCULAR1.data+OCULAR2.data);

mean_of_eye = mean(abs_of_eye_diff);
% threshold_of_eye_movements = mean_of_eye_movements*2;
threshold = mean_of_eye*params.sum_threshold_scale_factor; %30 uV was limit in paper "precise measures of REM"

first_pass_indices = abs_of_eye_diff>threshold&abs_of_eye_sum<mean_of_eye/params.diff_threshold_scale_factor;
first_pass = thresholdcrossings(first_pass_indices,0);



%once the eye movements have been found, make a second pass to pull them
%together in a useful way.  The output from processArtifacts is actually a\
% distanceApart_sec = 0.5;
distanceApart_sec = params.max_merge_time_sec;
merge_distance = distanceApart_sec*samplerate;
ocular_artifacts = CLASS_events.merge_nearby_events(first_pass, merge_distance);

% additional_buffer_sec = 0.1;
% ocular_artifacts = merge_events(first_pass, OCULAR1.sample_rate,...
%     distanceApart_sec,additional_buffer_sec);

detectStruct.new_data = abs_of_eye_sum;
detectStruct.new_events = ocular_artifacts;


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
