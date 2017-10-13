function detectStruct = detection_lm_wetter_raw(channel_index, optional_params)
% The criteria taken for this Leg Movement (LM) detector comes from
% Wetter TC, Dirlich G, Streit J, Trenkwalder C, Schuld A, Pollma ?cher T. 
%  An automatic method for scoring leg movements in polygraphic sleep
%  recordings and its validity in comparison to visual scoring. 
%    Sleep 2004;27:324?8" which was published in Journal Sleep Research 1996 (pp 273-5).
%
% The '_raw' version excludes any prefiltering in the algorithm and relies
% on previous filtering of the input channel to be done in advance.
%
% algorithm specifies "low" pass filtering at 16Hz
% (rectify the signal)
% Truncate to 30uV
% apply moving 0.15 sec moving standard deviation (pass 1)
% apply threshold of std amplitude > 0.6uV (pass 2) to determine 0.5 second or more
% continuous high activity
% Bridge within 0.5 seconds
%
% programmed by Hyatt Moore IV
% 6/17/2012 - Stanford, CA

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
            params.truncate_uV = 30; %truncate values to this level
            params.moving_std_window = 0.16;
            params.high_std_thresh = 0.6; 
            params.min_burst_dur_sec = 0.4; %80%
            params.merge_within_sec = 0.5;            
            params.min_duration_sec = 0.5;
            params.max_duration_sec = 10.0;
            plist.saveXMLPlist(pfile,params);
        end
    end
end

detectStruct.paramStruct = [];

%1. low pass filter (do ahead of this function call)
%2. rectify - does not say this.

data = abs(data);

%3. truncate to 30 uV
data(data>params.truncate_uV)=params.truncate_uV;
% data(data<params.truncate_uV)=-params.truncate_uV;
%4.  apply moving std (pass 1)
params.std.win_length_sec = params.moving_std_window;
params.std.sample_rate = sample_rate;
data = filter.nlfilter_std(data,params.std);
%5  classify with activity threshold (pass 2)
LM_candidates = thresholdcrossings(data,params.high_std_thresh);

%handle corner case - no detections
if(isempty(LM_candidates))
    detectStruct.new_events = [];
    detectStruct.new_data = data;
    
    detectStruct.paramStruct = paramStruct;
else
    LM_burst_min = ceil(params.min_burst_dur_sec*sample_rate);
    LM_dur_range = ceil([params.min_duration_sec, params.max_duration_sec]*sample_rate);
    
    %apply LM burst duration criteria...
    lm_dur = diff(LM_candidates');
    LM_candidates = LM_candidates(lm_dur>=LM_burst_min,:);
    
    %extend out to 0.5 seconds for LMs that are between 0.4 and 0.5
    %seconds to match with original burst criteria (80% of 0.5 seconds
    %indicates a 0.5 second LM)
    lm_dur = diff(LM_candidates');
    short_dur_ind =lm_dur<params.min_duration_sec; %indices of short duration bursts that need to be extended out.    
    
    %extend out the stop sample to be 0.5 second duration total
    LM_candidates(:,short_dur_ind) = LM_candidates(short_dur_ind,:)+params.min_duration_sec*sample_rate;

    %bridge nearby events
    merge_within = ceil(params.merge_within_sec*sample_rate);
    if(merge_within>0)
        LM_candidates = CLASS_events.merge_nearby_events(LM_candidates,merge_within);
    end        

    %apply LM duration criteria again because could possibly have more LM's
    %now.  
    lm_dur = diff(LM_candidates');
    LM_candidates = LM_candidates(lm_dur>=LM_dur_range(1) & lm_dur<=LM_dur_range(2),:);
    
    
    detectStruct.new_events = LM_candidates;
    detectStruct.new_data = data;    
    detectStruct.paramStruct = [];
end

end