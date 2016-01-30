function detectStruct = detection_spindles_dual_filter(channel_index,optional_params)
%this detector filters the channel for two bandpassed ranges - 2-4 and
%10-12 to look for spindles.  The idea being that the waxing and waning of
%the spindles come from the low frequency data.

global CHANNELS_CONTAINER;

% channel_obj = CHANNELS_CONTAINER.cell_of_channels{channel_index};
channel_obj.data = CHANNELS_CONTAINER.getData(channel_index);
channel_obj.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_spindles_dual_filter.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.filt1_low_freq = 1;
        params.filt1_high_freq = 3;
        params.filt2_low_freq = 10;
        params.filt2_high_freq = 14;
        params.rms_long_dur_min = 3;
        params.rms_short_dur_sec = 2;
        params.threshold_scale_factor = 2;


        plist.saveXMLPlist(pfile,params);
    end
end

params.filter_order = 100;

%this is currently unused...
% params.win_type = SPINDLE_DLG.win_type;
        
n = params.filter_order;
delay = (n)/2;
Wn = [params.filt1_low_freq params.filt1_high_freq, params.filt2_low_freq params.filt2_high_freq ]/channel_obj.sample_rate*2;
b = fir1(n,Wn,'DC-0');

% If Wn is a multi-element vector,
% Wn = [W1 W2 W3 W4 W5 ... WN],
%     FIR1 returns an order N multiband filter with bands
%     0 < W < W1, W1 < W < W2, ..., WN < W < 1.
%     B = FIR1(N,Wn,'DC-1') makes the first band a passband.
%     B = FIR1(N,Wn,'DC-0') makes the first band a stopband.
    
bp.line = filter(b,1,channel_obj.data);

%account for the delay...
bp.line = [bp.line(delay+1:end); zeros(delay,1)];


bp.rms_long = movingRMS(bp.line,params.rms_long_dur_min*60*channel_obj.sample_rate);

bp.rms_short = movingRMS(bp.line,params.rms_short_dur_sec*channel_obj.sample_rate);

bp.spindle_line = bp.rms_short > (bp.rms_long*params.threshold_scale_factor);

spindle_crossings = processArtifacts(bp.spindle_line,channel_obj.sample_rate);

% spindle_crossings_processed = merge_events(spindle_crossings,channel_obj.sample_rate);



spindles = [1 10];
detectStruct.new_data = bp.line;
detectStruct.new_events = spindle_crossings;
detectStruct.paramStruct = [];
