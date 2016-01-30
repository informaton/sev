function detectStruct = detection_spindles_bp(channel_index,optional_params)
global CHANNELS_CONTAINER;
global SPINDLE_DLG;

% channel_obj = CHANNELS_CONTAINER.cell_of_channels{channel_index};
channel_obj.data = CHANNELS_CONTAINER.getData(channel_index);
channel_obj.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_spindles_bp.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.low_freq = SPINDLE_DLG.low_freq;
        params.high_freq = SPINDLE_DLG.high_freq;
        params.rms_long_dur_min = SPINDLE_DLG.rms_long_min;
        params.rms_short_dur_sec = SPINDLE_DLG.rms_short_sec;
        params.threshold_scale_factor = SPINDLE_DLG.scale_factor;
        params.filter_order = SPINDLE_DLG.order;

        plist.saveXMLPlist(pfile,params);
    end
end

%this is currently unused...
% params.win_type = SPINDLE_DLG.win_type;
        
n = params.filter_order;
delay = (n)/2;
b = fir1(n,[params.low_freq params.high_freq]/channel_obj.sample_rate*2);

bp.line = filter(b,1,channel_obj.data);

%account for the delay...
bp.line = [bp.line(delay+1:end); zeros(delay,1)];


bp.rms_long = movingRMS(bp.line,params.rms_long_dur_min*60*channel_obj.sample_rate);

bp.rms_short = movingRMS(bp.line,params.rms_short_dur_sec*channel_obj.sample_rate);

bp.spindle_line = bp.rms_short > (bp.rms_long*params.threshold_scale_factor);

spindle_crossings = processArtifacts(bp.spindle_line,channel_obj.sample_rate);

% spindle_crossings_processed = merge_events(spindle_crossings,channel_obj.sample_rate);


detectStruct.new_data = bp.line;
detectStruct.new_events = spindle_crossings;
detectStruct.paramStruct = [];
