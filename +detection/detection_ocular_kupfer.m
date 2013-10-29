function detectStruct = detection_ocular_kupfer(channel_cell_data,varargin)
%detect eye movements from an EOG channel based on McPartland and Kupfer's
%paper, "Computerized measures of EOG activity during sleep" - 1977/1978
%
%
% Upper and Lower thresholds set to +/- 25uV
% the UTH and LTH must be crossed (one by each channel) within 100ms of
% each other to ensure binocular synchrony.
%
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
        params.threshold_uV = 25; %25uV threshold
        params.max_synchrony_duration_seconds = .10; %within 100 mseconds of each other
        plist.saveXMLPlist(pfile,params);


    end
end

OCULAR1.data = channel_cell_data{1};
samplerate = params.samplerate;
OCULAR2.data = channel_cell_data{2};

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