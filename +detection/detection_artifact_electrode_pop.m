%> @file
%> @brief Detect electrode pop in input signal.
%======================================================================
%> @brief Method looks for occurrences of electrode pop in the signal provided.
%> @param data Signal data vector.  
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c win_length_sec Duration to compute power spectrum over.
%> @li @c win_interval_sec Interval between consecutive power spectrum
%> calculations.
%
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data A copy of the input data
%> @li @c .new_events A two column matrix of start stop sample points of
%electrode pop detections, ordered consecutively by occurrence
%> @li @c .paramStruct Empty value returned (i.e. []).
function detectStruct = detection_artifact_electrode_pop(data,params,stageStruct)

% Author Hyatt Moore IV
% modified 3/1/2013 - remove global references and use varargin

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode



if(nargin==0)
    detectStruct = getDefaultParams();
else    
    if(nargin<2 && isempty(params))
        pfile =  strcat(mfilename('fullpath'),'.plist');
        params = getDefaultParams(pfile);
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

end

function defaultParams = getDefaultParams(pfile)
    if(nargin<1)
        pfile = [];
    end
    if(exist(pfile,'file'))
        %load it
        defaultParams = plist.loadXMLPlist(pfile);
    else
        pfile =  strcat(mfilename('fullpath'),'.plist');
        %make it and save it for the future        
        defaultParams.win_length_sec = 3;
        defaultParams.win_interval_sec = 3;
        plist.saveXMLPlist(pfile,defaultParams);
    end
end
