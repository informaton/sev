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
    % modified 9/15/2014 - streamline default parameter behavior.
    % Modified 8/23/2016 - corrected to handle case with different win length
    % sec and win interval sec
    
    
    % set default parameters
    defaultParams.win_length_sec = 6;
    defaultParams.win_interval_sec = 3;
    
    pop_threshold = 10000;
    % return default parameters if no arguments are provided
    if(nargin==0)
        detectStruct = defaultParams;
    else
        
        % load existing or default parameters if 1 argument is provided.
        if(nargin<2 || isempty(params))
            pfile = strcat(mfilename('fullpath'),'.plist');
            
            if(exist(pfile,'file'))
                %load it
                params = plist.loadXMLPlist(pfile);
            else
                params = defaultParams;
                plist.saveXMLPlist(pfile,defaultParams);
            end
        end
        
        if(iscell(data))
            data = data{1};
        end
        samplerate = params.samplerate;
        
        win_length_sec = params.win_length_sec;
        win_interval_sec = params.win_interval_sec;
        
        PSD_settings.removemean = true;
        PSD_settings.interval_sec = win_interval_sec;
        PSD_settings.FFT_window_sec=win_length_sec;
        PSD_settings.wintype = 'rectwin';
        PSD_settings.spectrum_type = 'power';
        psd_all = calcPSD(data,samplerate,PSD_settings);
        
        % [psd_all psd_x psd_nfft] = calcPSD(data,win_length_sec,win_interval_sec,samplerate,PSD.wintype,PSD.removemean);
        % event_indices = any(psd_all(:,2:end)'>5); %this vector contains good events
        % detectStruct.new_events = find(event_indices==0);
        
        event_indices = any(psd_all(:,2:end)'>pop_threshold); %this vector contains good events
        detectStruct.new_events = find(event_indices);
        
        event_length = samplerate*win_length_sec;
        interval_length = samplerate*win_interval_sec;
        starts = (detectStruct.new_events(:)-1)*interval_length+1;
        stops = starts+event_length-1;  %or ..detectStruct.new_events(:)*event_length;
        
        merge_within_samples = event_length;
        artifacts = [starts(:),stops(:)];
        artifacts = CLASS_events.merge_nearby_events(artifacts,merge_within_samples);
        
        detectStruct.new_events = artifacts;
        detectStruct.new_data = data;
        detectStruct.paramStruct = [];
    end
    
end


