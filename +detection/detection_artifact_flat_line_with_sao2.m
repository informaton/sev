function detectStruct = detection_artifact_flat_line_with_sao2(channel_data_cell,varargin)
%channel_index is the index of the CLASS in the CLASS_channel_containerCell
%global variable that will be processed for artifact.
%looks for occurrences of flat lining in the signal associated with channel
%index.  detectStruct.new_data will be returned as empty in this case.  
%detectStruct.new_events will be a matrix of start stop points of flat line detections
%in terms of the sample index withing the raw data associated with
%channel_index
%
%This detection method will search for indices when the saO2 channel is
%below a set threshold (0.1 here)
%A second pass is then conducted to determine if the primary channel is
%below a given power threshold during this time.
%if both criteria are met, then first pass saO2 channel detection is
%registered as an event, otherwise it is not.

%written Hyatt Moore IV
% modified: added varargin parameter
global PSD;


if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.win_length_sec = 5;
        params.win_interval_sec = 5;
        params.min_power = 0.1;
        params.saO2_min_pct = 10; %this is 10%
        plist.saveXMLPlist(pfile,params);
    end
end


% global CHANNEL_INDICES;
% channel_obj = CHANNELS_CONTAINER.cell_of_channels{channel_indices(1)};
src_data = channel_data_cell{1};
samplerate = params.samplerate;
saO2_data = channel_data_cell{2};

saO2_detections = thresholdcrossings(saO2_data<params.saO2_min_pct,0);
num_detections = size(saO2_detections,1);
second_pass_detections =  true(num_detections,1);

win_length_sec = params.win_length_sec;
win_interval_sec = params.win_interval_sec;

PSD_settings.removemean = PSD.removemean;
PSD_settings.interval = win_interval_sec;
PSD_settings.FFT_window_sec=win_length_sec;
PSD_settings.wintype = PSD.wintype;

for k=1:num_detections
    psd_all = calcPSD(src_data(saO2_detections(k,1):saO2_detections(k,2)),...
        samplerate,PSD_settings);

    if(all(psd_all(:,2:end)'<params.min_power))
        second_pass_detections(k)=true;
    end;
end;

detectStruct.new_events = saO2_detections; %(second_pass_detections,:);
detectStruct.new_data = src_data;
detectStruct.paramStruct = [];
    
end

