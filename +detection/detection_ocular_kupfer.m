%> @file
%> @brief Eye movement detector based on McPartland and Kupfer's
%> paper, "Computerized measures of EOG activity during sleep" - 1977/1978  
%======================================================================
%> @brief Detect eye movements from an EOG channel based on McPartland and Kupfer's
%paper, "Computerized measures of EOG activity during sleep" - 1977/1978
%> The method requires the upper and lower threshold crossings (one by each channel) within 100ms of
%> each other to ensure binocular synchrony.
%
%> @param data_cell Two element cell of equal lengthed digitized EOG channel samples
%> @param params A structure for variable parameters passed in
%> with following fields  {default}
%> @li @c params.threshold_uV Upper and Lower amplitude thresholds set to +/- 25uV {25}
%> @li @c params.max_synchrony_duration_seconds = .10; %within 100 mseconds of each other
%
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Smoothed version of first input data (i.e.
%> data_cell{1}).
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Unused (i.e. []).
function detectStruct = detection_ocular_kupfer(data_cell,param, stageStruct)

% Implemented by  Hyat Moore IV
% modified: 5/24/12 - handle case where only one channel is being used
% (same source_indices).
%modified 3/1/2013 - remove global references and use varargin


%if I am trying to apply this to the same channel (e.g. PTSD data with just
%the HEOG channel and need to reverse one channel's polarity to make it
%work with Kupfer
% if(numel(channel_cell_data==1)))
%     OCULAR2.data = -OCULAR2.data;
% end


if(nargin<2 || isempty(params))     
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.threshold_uV = 25; %25uV threshold
        params.max_synchrony_duration_seconds = .10; %within 100 mseconds of each other
        plist.saveXMLPlist(pfile,params);


    end
end

OCULAR1.data = data_cell{1};
samplerate = params.samplerate;
OCULAR2.data = data_cell{2};

%establish the detection parameters

threshold = params.threshold_uV;
UTH = threshold; %upper and lower thresholds that need to be crossed...
LTH = -threshold;
max_synchrony_duration_seconds = params.max_synchrony_duration_seconds;
duration_threshold = max_synchrony_duration_seconds*samplerate;


%arbitrarily pick one of the two channels to begin with
%smooth the data with a moving averager
n = 11;
b = ones(1,n)/n;
smooth_oc1 = filter(b,1,OCULAR1.data);


oc1_pass1 = thresholdcrossings(abs(smooth_oc1),threshold);
detectStruct.new_events = zeros(size(oc1_pass1));
num_events = 0;
channel_length = numel(OCULAR1.data);

for k=1:size(oc1_pass1,1)
    start = oc1_pass1(k,1);
    range = ceil(max(1, start-duration_threshold)):floor(min(start+duration_threshold,channel_length));

    if(OCULAR1.data(start)>UTH)
        if(any(OCULAR2.data(range)<LTH))
            num_events = num_events+1;
            detectStruct.new_events(num_events,:) = oc1_pass1(k,:);
        end;
    else
        if(any(OCULAR2.data(range)>UTH))
            num_events = num_events+1;
            detectStruct.new_events(num_events,:) = oc1_pass1(k,:);
        end;
        
    end
    
end

detectStruct.new_events = detectStruct.new_events(1:num_events,:);

min_duration_sec = 0.1;
min_duration_samples = min_duration_sec*samplerate;
detectStruct.new_events = CLASS_events.cleanup_events(detectStruct.new_events,min_duration_samples);
detectStruct.new_data =  smooth_oc1;%OCULAR1.data;
detectStruct.paramStruct = [];

end