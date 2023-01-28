function detectStruct = detection_spindles_bp(channel_data,params, stageStruct)

% return default parameters if no input arguments are provided.

% initialize default parameters
defaultParams.low_freq = 10;
defaultParams.high_freq = 18;
defaultParams.rms_long_dur_min = 5;
defaultParams.rms_short_dur_sec = 2;
defaultParams.threshold_scale_factor = 1.5;
defaultParams.filter_order = 100;

% return default parameters if no input arguments are provided.

if(nargin==0)
    detectStruct = defaultParams;
else
    
    if(nargin<2 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future            
            params = defaultParams;
            plist.saveXMLPlist(pfile,params);
        end
    end
    samplerate = params.samplerate;

    %this is currently unused...
    % params.win_type = SPINDLE_DLG.win_type;
        
    n = params.filter_order;
    delay = (n)/2;
    b = fir1(n,[params.low_freq params.high_freq]/samplerate*2);

    bp.line = filter(b,1,channel_data);

    %account for the delay...
    bp.line = [bp.line(delay+1:end); zeros(delay,1)];


    bp.rms_long = movingRMS(bp.line,params.rms_long_dur_min*60*samplerate);

    bp.rms_short = movingRMS(bp.line,params.rms_short_dur_sec*samplerate);

    bp.spindle_line = bp.rms_short > (bp.rms_long*params.threshold_scale_factor);

    spindle_crossings = processArtifacts(bp.spindle_line,samplerate);

    % spindle_crossings_processed = merge_events(spindle_crossings,channel_obj.sample_rate);


    detectStruct.new_data = bp.line;
    detectStruct.new_events = spindle_crossings;
    detectStruct.paramStruct = [];
end
end