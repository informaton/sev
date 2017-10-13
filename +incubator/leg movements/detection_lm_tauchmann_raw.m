function detectStruct = detection_lm_tauchmann_raw(channel_index, optional_params)
% The criteria taken for this Leg Movement (LM) detector comes from the
% letter to the editor, titled, "Automatic detection of periodic leg
% movements (plm)" which was published in Journal Sleep Research 1996 (pp
% 273-5).
% The '_raw' version excludes any prefiltering in the algorithm and relies
% on previous filtering of the input channel to be done in advance.
%
% algorithm specifies high pass filtering at 16Hz
% rectify the signal
% threshold above 7uV
% merge within 0.15 seconds
% calculate AUC
% reject AUC < 5 uV
%
% programmed by Hyatt Moore IV
% 6/15/2012 - Stanford, CA

global CHANNELS_CONTAINER;

if(numel(channel_index)>20)
    data = channel_index;
    params = optional_params;
    sample_rate = params.sample_rate;
else
    
    % LEG_channel = CHANNELS_CONTAINER.cell_of_channels{channel_index};
    data = CHANNELS_CONTAINER.getData(channel_index);
    sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);
    
    %this allows direct input of parameters from outside function calls, which
    %can be particularly useful in the batch job mode
    if(nargin==2 && ~isempty(optional_params))
        params = optional_params;
    else
        pfile = strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future
            %         params.operation = 'mean';
            %         params.filter_order = 50;%1/2 second worth at 100Hz sampling rate
            params.threshold_uV = 9;  %7 uV above resting - presumably resting is 2uV
            params.min_duration_sec = 0.5;
            params.max_duration_sec = 10.0;
            params.merge_within_sec = 0.15;
            params.min_auc = 5;
            plist.saveXMLPlist(pfile,params);
            
        end
    end
end

% params.filter_order = sample_rate; %typically want this at 100

detectStruct.paramStruct = [];

%2. rectify
data = abs(data);

%3.  apply single threshold criteria
LM_candidates = thresholdcrossings(data,params.threshold_uV);


%handle corner case - no detections
if(isempty(LM_candidates))
    detectStruct.new_events = [];
    detectStruct.new_data = data;
    
    AUC = [];
    paramStruct.AUC = AUC;
    detectStruct.paramStruct = paramStruct;
else
    merge_within = ceil(params.merge_within_sec*sample_rate);
    if(merge_within>0)
        LM_candidates = CLASS_events.merge_nearby_events(LM_candidates,merge_within);
    end
        

    LM_dur_range = ceil([params.min_duration_sec, params.max_duration_sec]*sample_rate);
    
    %2.  apply LM lm duration criteria...
    lm_dur = diff(LM_candidates');
    LM_candidates = LM_candidates(lm_dur>=LM_dur_range(1) & lm_dur<=LM_dur_range(2),:);
    
    %apply AUC criteria
    duration = diff(LM_candidates')'+1;

    AUC = zeros(size(duration)); %area under the curve
    for k =1:numel(AUC)
        AUC(k) = sum(data(LM_candidates(k,1):LM_candidates(k,2)))/duration(k);
    end
    
    okay_indices = AUC>params.min_auc;
    
    detectStruct.new_events = LM_candidates(okay_indices,:);
    detectStruct.new_data = data;    
    paramStruct.AUC = AUC(okay_indices);    
    detectStruct.paramStruct = paramStruct;
end

end