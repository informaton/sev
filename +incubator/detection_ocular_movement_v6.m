function detectStruct = detection_ocular_movement_v6(channel_cell_data,varargin)
%differs from v5 in the same way v4 differs from v2 (can adjust to less
%strict criteria for final eye movement call once an eyemovement is called
%correctly the first time.  
%source_indices(1) = ocular channel 1
%source_indices(2) = ocular channel 2

%written by Hyatt Moore
% modified 1/6/2013 - changed sample_rate to samplerate
% Date: 1/23/2013
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
        params.diff_threshold_scale_factor = 2; %diff of EMs should be greater than this for EOG values on first pass
        params.third_threshold_scale_factor = 0.5; %diff of EMs should be greater than this for EOG values on second/third pass
        params.xcorr_threshold = -0.5; %values should be negatively correlated between -0.5 and -1.0
        plist.saveXMLPlist(pfile,params);
    end
end

params.operation = 'mean';        

OCULAR1.data = channel_cell_data{1};
OCULAR2.data = channel_cell_data{2};
samplerate = params.samplerate;

abs_of_eye_diff = abs(OCULAR1.data-OCULAR2.data); %should be large for synchronous eye movements

mean_of_eye = mean(abs_of_eye_diff);
%mean_of_eye = mean(abs_of_eye_sum) %almost identical here

% threshold_of_eye_movements = mean_of_eye_movements*2;
diff_threshold = mean_of_eye*params.diff_threshold_scale_factor; %30 uV was limit in paper "precise measures of REM"
first_pass = thresholdcrossings(abs_of_eye_diff, diff_threshold);

second_pass = zeros(size(first_pass));
second_row = 0; %counter for this algorithm, keeps track of the values used.

%second pass is the xcorr result...

for row=1:size(first_pass,1)
    range_ind = first_pass(row,1):first_pass(row,2);
    p = xcorr(OCULAR1.data(range_ind),OCULAR2.data(range_ind),0,'coeff');
    if(p<params.xcorr_threshold)
        second_row = second_row+1;
        second_pass(second_row,:)=first_pass(row,:);
    end
        
%         start = find(third_pass(:,1)<range_ind(1),1,'last');
%         stop = find(third_pass(:,2)>range_ind(end),1,'first');
%         if(isempty(start))
%             start =range_ind(1);
%         else
%             start = third_pass(start,1);
%         end
%         if(isempty(stop))
%             stop = range_ind(end);
%         else
%             stop = third_pass(stop,2);
%         end
%         second_pass(second_row,:)=[start,stop];
%     end
end

second_pass = second_pass(1:second_row,:);

%now go back and expand the ones we have caught.
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
    
    %merge events that are within 1/25th of a second of each other samples of each other    
    merge_distance = round(1/25*samplerate);
    detectStruct.new_events = CLASS_events.merge_nearby_events(detectStruct.new_events,merge_distance);
else
    detectStruct.new_events = []; %no events were found otherwise
end


detectStruct.new_data = OCULAR1.data;
detectStruct.paramStruct = [];
