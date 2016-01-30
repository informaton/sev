function detectStruct = detection_stage_sleepCycles(channel_index,optional_params)
%determine sleep cycles from the current stage file and return as events
%for each epoch
%Author: Hyatt Moore IV
%Created: 9.26.2012

%relies on WORKSPACE global struct to get current filename and consequent
%.SCO data

global CHANNELS_CONTAINER;
global BATCH_PROCESS;
global STAGES;
global DEFAULTS;

data = CHANNELS_CONTAINER.getData(channel_index(1));
sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(1));

if(isfield(BATCH_PROCESS,'stages_filename'))
    epoch_dur_sec = BATCH_PROCESS.standard_epoch_sec;    
else
    epoch_dur_sec = DEFAULTS.standard_epoch_sec;
end

window_len = epoch_dur_sec*sample_rate;

starts= (1:window_len:numel(data))';
stops = [starts(2:end)-1;numel(data)];
new_events = [starts,stops]; 


detectStruct.new_events = new_events;
detectStruct.new_data = data;
detectStruct.paramStruct.cycle = scoreSleepCycles(STAGES.line);
