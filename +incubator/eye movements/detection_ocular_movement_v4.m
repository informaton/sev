function detectStruct = detection_ocular_movement_v4(channel_cell_data,varargin)
%differs from detection_ocular_movement_v2 functinon in that after retrieving the same
%results as v2, it then finds a lower threshold that the events also fall into
%and uses this lower threshold as the events' start stop positions.
%source_indices(1) = ocular channel 1
%source_indices(2) = ocular channel 2

%% % written by Hyatt Moore IV
% modified 1/6/2013 -
% added clean up/merge code to handle overlaps, and req'd samplerate var
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input


%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.sum_threshold_scale_factor = 2; %sum of EMs should be less than this for added EOG values on first pass
        params.diff_threshold_scale_factor = 2; %diff of EMs should be greater than this for EOG values on first pass
        params.third_threshold_scale_factor = 0.5; %diff of EMs should be greater than this for EOG values on second/third pass
        plist.saveXMLPlist(pfile,params);
    end
end

params.operation = 'mean';     

OCULAR1.data = channel_cell_data{1};
OCULAR2.data = channel_cell_data{2};
samplerate = params.samplerate;
abs_of_eye_diff = abs(OCULAR1.data-OCULAR2.data); %should be large for synchronous eye movements
abs_of_eye_sum = abs(OCULAR1.data+OCULAR2.data); %should be small for synchronous eye movements

mean_of_eye = mean(abs_of_eye_diff);
%mean_of_eye = mean(abs_of_eye_sum) %almost identical here

% threshold_of_eye_movements = mean_of_eye_movements*2;
diff_threshold = mean_of_eye*params.diff_threshold_scale_factor; %30 uV was limit in paper "precise measures of REM"
sum_threshold = mean_of_eye*params.sum_threshold_scale_factor;
two_pass_indices = (abs_of_eye_diff>diff_threshold)&(abs_of_eye_sum<sum_threshold);
second_pass = thresholdcrossings(two_pass_indices);

third_threshold = mean_of_eye*params.third_threshold_scale_factor;
third_pass = thresholdcrossings(abs_of_eye_diff,third_threshold);

final_pass = zeros(size(second_pass));

third_row = 1;
final_row =1;

num_third_rows = size(third_pass,1);

if(num_third_rows>0)
    %the objective is to go through the second pass events in order and fill in
    %the final events with the locations of the third pass events which contain
    %any instances of the second pass events - this should "stretch" out the
    %second pass detections to a more realistic eye movement location since the
    %threshold has been reduced, but is only applied in the areas that have met
    %the more rigorous second-pass threshold.
    for second_row = 1:size(second_pass,1)
        if(second_pass(second_row,1) >= final_pass(final_row,1) && second_pass(second_row,1) <= final_pass(final_row,2))
            final_pass(final_row,2) = max(final_pass(final_row,2),second_pass(second_row,2));
        else
            %while we have not reached the end of the third row matrix and
            %while we have not found a spot where the second pass detections are
            %located within the third pass detections
            while(third_row <= num_third_rows && third_pass(third_row,1)<second_pass(second_row))
                third_row = third_row+1;
            end
            
            
            %don't overwrite a currently good event if it exists...
            if(any(final_pass(final_row,:)))
                final_row = final_row+1;
            end;
            
            %have to fill in with the second pass results, when no more third
            %pass results exists
            if(third_row > num_third_rows)
                final_pass(final_row,:) = second_pass(second_row,:);
                
                %otherwise, fill in with the desirable third pass results
            else
                if(third_row>1)
                    final_pass(final_row,:) = third_pass(third_row-1,:);
                else
                    final_pass(final_row,:) = third_pass(1,:);
                end
            end
            
        end
    end
    detectStruct.new_events = final_pass(1:final_row,:); %just take the events that were filled - no 0's
    merge_distance = round(1/25*samplerate);
    detectStruct.new_events = CLASS_events.merge_nearby_events(detectStruct.new_events,merge_distance);
else
    detectStruct.new_events = []; %no events were found otherwise
end

detectStruct.new_data = OCULAR1.data;
detectStruct.paramStruct = [];