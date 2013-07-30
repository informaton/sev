function detectStruct = detection_artifact_hp_20hz(data,varargin)
% Author Hyatt Moore IV
% modified 3/1/2013 - remove global references and use varargin

% channel = CHANNELS_CONTAINER.cell_of_channels{channel_index};

%updates the artifacts - called from updatePlot or in batch processing modes, and typically revolves
%around a flag being set
%CLASS_index is the index of the CLASS in the CLASS_channel_containerCell
%global variable that will be processed for artifact.
%parameters = (ARTIFACT_DLG,[data])
%if data is included it will be used as the data to high
%pass filter, and the delay compensated result will be stored
%in the objects data parameter - this is good when the
%object is being used as an event and the results of this
%detection method need to be displayed/plotted for
%understanding


% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.scale_factor=1.5;
        params.rms_short_sec=2;
        params.rms_long_min=5;
        params.additional_bufer_sec = 1; %add this to the left and right of each event.
        
        params.merge_within_sec = 5;
        
        plist.saveXMLPlist(pfile,params);
    end
end

samplerate = params.samplerate;

n = 100;
delay = (n)/2;

start = 20;
b = fir1(n,start/samplerate*2,'high');

hp_20Hz_data = filter(b,1,data);
%account for the delay...
hp_20Hz_data = [hp_20Hz_data((delay+1):end); zeros(delay,1)];

longparams.win_length_samples = params.rms_long_min*60*samplerate;
hp_20Hz_rms_long = filter.nlfilter_quickrms(hp_20Hz_data,longparams);

shortparams.win_length_samples = params.rms_short_sec*samplerate;
hp_20Hz_rms_short = filter.nlfilter_quickrms(hp_20Hz_data,shortparams);

%initialize variables here, to make sure we don't run into problems later
%with repeat file loads and not resetting these values...
hp_20Hz_crossings = thresholdcrossings(hp_20Hz_rms_short,hp_20Hz_rms_long*params.scale_factor);
buffer_samples = params.additional_buffer_sec*samplerate;  %tack on extra buffer to the edges.
detectStruct.new_data = hp_20Hz_data;
detectStruct.new_events = CLASS_events.buffer_then_merge_nearby_events(hp_20Hz_crossings,samplerate,buffer_samples,numel(data));
detectStruct.paramStruct = [];
end
