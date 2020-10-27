%> @file detection_artifact_flat_line.cpp
%> @brief Detects sections of data that have <i>flat lined</i>.
%======================================================================
%> @brief Determines flat lined section of input data.
%> @param data Signal data as a column vector.  
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c win_length_sec Window duration to calculate power from
%> @li @c win_interval_sec Interval in seconds to estimate power from
%> @li @c min_power Scalar value representing minimum power level allowed before flat line detection.
%
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data Empty in this case (i.e. []).
%> @li @c .new_events A two column matrix of start stop sample points of
%> the consecutively ordered flat line detections (i.e. per row).
%> @li @c .paramStruct Empty value returned (i.e. []).
%> @note global MARKING is used here for PSD settings @e removemean and
%> @e wintype.
function detectStruct = detection_artifact_flat_line(data,params,stageStruct)

global MARKING;

% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.win_length_sec = 5;
defaultParams.win_interval_sec = 5;
defaultParams.min_power = 0.01;

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
    
    
    win_length_sec = params.win_length_sec;
    win_interval_sec = params.win_interval_sec;
    
    PSD_settings.removemean = MARKING.SETTINGS.PSD.removemean;
    PSD_settings.interval_sec = win_interval_sec;
    PSD_settings.FFT_window_sec=win_length_sec;
    PSD_settings.wintype = MARKING.SETTINGS.PSD.wintype;
    PSD_settings.spectrum_type = 'power'; % 'psd' or 'none' also valid
    psd_all = calcPSD(data,params.samplerate,PSD_settings);
    
    % [psd_all psd_x psd_nfft] = calcPSD(channel_obj.data,win_length_sec,win_interval_sec,channel_obj.sample_rate,PSD.wintype,PSD.removemean);
    
    %calculate the PSD
    % if(CHANNEL_INDICES.PSD==channel_index && size(PSD.y_all,1)==numel(channel_obj.data)/(PSD.interval*channel_obj.sample_rate)) %don't recalculate PSD if already exists
    %     psd_all = PSD.y_all;
    %     psd_x = PSD.x;
    %     psd_nfft = PSD.nfft;
    % else
    % [psd_all psd_x psd_nfft] = calcPSD(channel_obj.data,win_length_sec,win_interval_sec,channel_obj.sample_rate,PSD.wintype,PSD.removemean);
    % end;
    
    % psd_all = sum(psd_all)/size(psd_all,1);
    % event_indices = any(psd_all(:,2:end)'>5); %this vector contains good events
    % detectStruct.new_events = find(event_indices==0);
    
    event_indices = any(psd_all(:,2:end)'>params.min_power); %this vector contains good events
    detectStruct.new_events = find(~event_indices);
    
    event_length = params.samplerate*win_length_sec;
    starts = (detectStruct.new_events(:)-1)*event_length+1;
    stops = starts-1+event_length;  %or ..detectStruct.new_events(:)*event_length;
    
    detectStruct.new_events = [starts(:),stops(:)];
    detectStruct.new_data = data;
    detectStruct.paramStruct = [];
    
end
end