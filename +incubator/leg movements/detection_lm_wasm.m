function detectStruct = detection_lm_wasm(source_indices, optional_params)
%  The WASM PLM protocol states: 
% "Calibration used in the past based on definitions of maximum  
% dorsiflexion at the ankle withuot resistance, was considered too vague
% and susceptible to technician differences to be useful. It was
% therefore  unanimously decided to use the absolute increase in
% microvolts for  detecting a significant event...Aside from meeting the
% criteria as   defined below there are no magnitude requirements." 

% WASM criteria
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
global CHANNELS_CONTAINER;
global STAGES;
%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_lm_wasm.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
%         params.operation = 'mean';
%         params.filter_order = 50;%1/2 second worth at 100Hz sampling rate
        params.merge_threshold_within_sec = 0.5;
        params.upper_threshold = 10;
        params.merge_lm_within_sec = 4.0;
        
        plist.saveXMLPlist(pfile,params);
        
    end
end

params.stages2exclude = [0,7];

% LEG_channel = CHANNELS_CONTAINER.cell_of_channels{source_indices(1)};
LEG_channel.data = CHANNELS_CONTAINER.getData(source_indices(1));
LEG_channel.sample_rate = CHANNELS_CONTAINER.getSamplerate(source_indices(1));

detectStruct.paramStruct = [];

%1. High pass filter the channel
% LM_DLG.order = params.filter_order; 
% LM_DLG.w = 20; %20+ Hz

% n = LM_DLG.order;
% delay = (n)/2;
% b = fir1(n,LM_DLG.w/LEG_channel.sample_rate*2,'high');

LM_line = LEG_channel.data;
% 
% if(nargin == 2)
%     LM_line = filter(b,1,optional_data);
% else
%     LM_line = filter(b,1,LEG_channel.data);
% end
% 
% 
% %account for the delay...
% LM_line = [LM_line(delay+1:end); zeros(delay,1)];
% 

lm_threshold = params.upper_threshold; %30 uV;
LM = thresholdcrossings(abs(LM_line),lm_threshold);

%merge within .1 seconds of each other. - another method would be to smooth
%the filtered line using an MA filter...
merge_min_dur = params.merge_threshold_within_sec;
merge_min_samples = round(merge_min_dur*LEG_channel.sample_rate);
LM = CLASS_events.merge_nearby_events(LM,merge_min_samples);

%2.  apply LM lm duration criteria...
min_dur = .5;
LM_DLG.duration_sec = [min_dur 10]; %15 seconds for research...
LM_dur_range = LM_DLG.duration_sec*LEG_channel.sample_rate;
lm_dur = diff(LM');
LM = LM(lm_dur>=LM_dur_range(1) & lm_dur<=LM_dur_range(2),:);

%3.  merge movements within 4 seconds of each other
min_dur_sec = params.merge_lm_within_sec;
min_samples = round(min_dur_sec*LEG_channel.sample_rate);
LM = CLASS_events.merge_nearby_events(LM,min_samples);

epochs = sample2epoch(LM,30,LEG_channel.sample_rate);
stages = STAGES.line(epochs);
excluded_indices = false(size(epochs,1),2);

for k=1:numel(params.stages2exclude)
    stage2exclude = params.stages2exclude(k);
    excluded_indices = excluded_indices|stages==stage2exclude;
end
excluded_rows = excluded_indices(:,1)|excluded_indices(:,2);

detectStruct.new_events = LM(~excluded_rows,:);
detectStruct.new_data = LM_line;
detectStruct.paramStruct = [];


end