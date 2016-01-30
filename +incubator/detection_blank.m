function detectStruct = detection_blank(channel_index,optional_params)
global CHANNELS_CONTAINER;

channel_obj = CHANNELS_CONTAINER.cell_of_channels{channel_index};


% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_blank.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        
        params.long_window_sec = 180;
        params.short_window_sec = 4;
        params.threshold_scale = 4;
        plist.saveXMLPlist(pfile,params);
        
        
    end
end

params.wintype = 'rectwin';

detectStruct.new_data = [];
detectStruct.new_events = [];
detectStruct.paramStruct = [];

