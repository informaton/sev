function detectStruct = detection_spindles_dual_bp(channel_index,optional_params)
global CHANNELS_CONTAINER;
% global SPINDLE_DLG;

% channel_obj = CHANNELS_CONTAINER.cell_of_channels{channel_index};
channel_obj.data = CHANNELS_CONTAINER.getData(channel_index);
channel_obj.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_spindles_dual_bp.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.filt1_low_freq = 1;
        params.filt1_high_freq = 3;
        params.filt2_low_freq = 10;
        params.filt2_high_freq = 13;
        params.rms_long_dur_min = 5;
        params.rms_short_dur_sec = 2;
        params.threshold_scale_factor = 1.5;


        plist.saveXMLPlist(pfile,params);
    end
end
params.filter_order = 100;

%this is currently unused...
% params.win_type = SPINDLE_DLG.win_type;
        
n = params.filter_order;
delay = (n)/2;

B1 = fir1(n,[params.filt1_low_freq params.filt1_high_freq]/channel_obj.sample_rate*2);

bp1.line = filter(B1,1,channel_obj.data);

%account for the delay...
bp1.line = [bp1.line(delay+1:end); zeros(delay,1)];


bp1.rms_long = movingRMS(bp1.line,params.rms_long_dur_min*60*channel_obj.sample_rate);

bp1.rms_short = movingRMS(bp1.line,params.rms_short_dur_sec*channel_obj.sample_rate);

bp1.spindle_line = bp1.rms_short > (bp1.rms_long*params.threshold_scale_factor);

B2 = fir1(n,[params.filt2_low_freq params.filt2_high_freq]/channel_obj.sample_rate*2);

bp2.line = filter(B2,1,channel_obj.data);

%account for the delay...
bp2.line = [bp2.line(delay+1:end); zeros(delay,1)];


bp2.rms_long = movingRMS(bp2.line,params.rms_long_dur_min*60*channel_obj.sample_rate);

bp2.rms_short = movingRMS(bp2.line,params.rms_short_dur_sec*channel_obj.sample_rate);

bp2.spindle_line = bp2.rms_short > (bp2.rms_long*params.threshold_scale_factor);

bp.spindle_line = bp1.spindle_line&bp2.spindle_line;

spindle_crossings = processArtifacts(bp.spindle_line,channel_obj.sample_rate);

% spindle_crossings_processed = merge_events(spindle_crossings,channel_obj.sample_rate);


detectStruct.new_data = bp2.line+bp1.line;
detectStruct.new_events = spindle_crossings;
detectStruct.paramStruct = [];
