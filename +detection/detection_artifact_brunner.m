%> @file detection_artifact_brunner.cpp
%> @brief Determines sections of artifact using Brunner method.
%> The method using a moving median filter with adaptive thresholds as
%> determined by the surrounding time windows of different lengths.  The
%> paper settled on a threshold of 4 times the median value for a surround 3
%> minute window.  Three minutes was picked in this case because epochs were
%> scored in 60 second blocks for the study done in 1996.  
%======================================================================
%> @brief EEG artifact detector based on the 1996 paper by Brunner titled, "Muscle artifacts in the sleep
%> EEG: automated detection and effect on all-night EEG power spectra"
%> @param data Signal data vector.  
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c long_window_sec Window duration in seconds to estimate background
%> power from
%> @li @c short_window_sec Window duration in seconds to estimate local
%> power from
%> @li @c threshold_scale Detection threshold scalar value applied to power level obtained from long_window_sec
%> that the local power obtained from short_window_sec must exceed to detect an artifact.
%>
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data Empty in this case (i.e. []).
%> @li @c .new_events A two column matrix of start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c .paramStruct Empty value returned (i.e. []).
function detectStruct = detection_artifact_brunner(data,params,stageStruct)

% Implemented by  Hyat Moore IV
% modified 3/1/2013 - remove global references and use varargin
% modified 9/15/2014 - streamline default parameter behavior.


pfile = strcat(mfilename('fullpath'),'.plist');

% set default parameters
defaultParams.long_window_sec = 180;
defaultParams.short_window_sec = 4;
defaultParams.threshold_scale = 4;
        
% return default parameters if no arguments are provided
if(nargin==0)     
    plist.saveXMLPlist(pfile,defaultParams);
    detectStruct = defaultParams;    
else    
    
    % load existing or default parameters if 1 argument is provided.
    if(nargin<2 || isempty(params))
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else        
            params = defaultParams;
            plist.saveXMLPlist(pfile,defaultParams);            
        end
    end
    
    params.wintype = 'rectwin';
    
    samplerate = params.samplerate;
    
    PSD_settings.removemean = true;
    PSD_settings.interval = params.short_window_sec;
    PSD_settings.FFT_window_sec=params.short_window_sec;
    PSD_settings.wintype = params.wintype;
    
    channel_psd = calcPSD(data,samplerate,PSD_settings);
    
    % channel_psd = calcPSD(channel_obj.data,params.short_window_sec,params.short_window_sec,channel_obj.sample_rate);
    
    %obtain the frequency band/range of interest
    spectrum = [26.25 32];
    spectrum_ind = round(spectrum/(samplerate/size(channel_psd,2)));
    spectrum_ind(1) = max(1,spectrum_ind(1)); %do not want 0 index
    spectrum_ind = spectrum_ind(1):spectrum_ind(2);
    
    spectrum_psd = sum(channel_psd(:,spectrum_ind),2);
    median_vals = moving_median_filter(spectrum_psd,round(params.long_window_sec/params.short_window_sec));
    
    new_evt_ind = find(spectrum_psd>median_vals(:)*params.threshold_scale);
    new_evt_ind = (new_evt_ind-1)*params.short_window_sec*samplerate+1;
    
    detectStruct.new_events = [new_evt_ind(:), new_evt_ind(:)+params.short_window_sec*samplerate-1];
    detectStruct.new_data = data;
    detectStruct.paramStruct = [];
end
end
