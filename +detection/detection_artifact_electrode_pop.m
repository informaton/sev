function detectStruct = detection_artifact_electrode_pop(data,varargin)
%channel_index is the index of the CLASS in the CLASS_channel_containerCell
%global variable that will be processed for artifact.
%looks for occurrences of flat lining in the signal associated with channel
%index.  detectStruct.new_data will be returned as empty in this case.  
%detectStruct.new_events will be a matrix of start stop points of flat line detections
%in terms of the sample index withing the raw data associated with
%channel_index

% Author Hyatt Moore IV
% modified 3/1/2013 - remove global references and use varargin

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        
        params.win_length_sec = 3;
        params.win_interval_sec = 3;
        plist.saveXMLPlist(pfile,params);
        
        
    end
end

if(iscell(data))
    data = data{1};
end
samplerate = params.samplerate;

win_length_sec = params.win_length_sec;
win_interval_sec = params.win_interval_sec;

PSD_settings.removemean = true;
PSD_settings.interval = win_interval_sec;
PSD_settings.FFT_window_sec=win_length_sec;
PSD_settings.wintype = 'rectwin';

psd_all = calcPSD(data,samplerate,PSD_settings);


% [psd_all psd_x psd_nfft] = calcPSD(data,win_length_sec,win_interval_sec,samplerate,PSD.wintype,PSD.removemean);


% event_indices = any(psd_all(:,2:end)'>5); %this vector contains good events
% detectStruct.new_events = find(event_indices==0);

event_indices = any(psd_all(:,2:end)'>1000); %this vector contains good events
detectStruct.new_events = find(event_indices);

event_length = samplerate*win_interval_sec;
starts = (detectStruct.new_events(:)-1)*event_length+1;
stops = starts+event_length-1;  %or ..detectStruct.new_events(:)*event_length;

detectStruct.new_events = [starts(:),stops(:)];
detectStruct.new_data = data;
detectStruct.paramStruct = [];

end
