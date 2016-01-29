%> @file detection_artifact_hp_20hz.cpp
%> @brief EEG detection of high frequency noise.
%======================================================================
%> @brief Determines high frequency noise in input signal (e.g. EEG).
%> @param data Signal data vector.  
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c scale_factor
%> @li @c rms_short_sec Window duration in seconds to estimate local activity.
%> @li @c rms_long_min Window duration in seconds to estimate background
%> activity
%> @li @c additional_buffer_sec Addiotional buffer in seconds to increase the onset and offset of detected events by.
%> @li @c merge_within_sec Window duration that consecutive events are merged within.
%>
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data Data after high pass filtering at 20 Hz.
%> @li @c .new_events A two column matrix of start stop sample points of
%> electrode pop detections, ordered consecutively by occurrence
%> @li @c .paramStruct Empty value returned (i.e. []).
function detectStruct = detection_artifact_hp_20hz(data,params,stageStruct)
% Author Hyatt Moore IV
% modified 3/1/2013 - remove global references and use varargin
% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.scale_factor=1.5;
defaultParams.rms_short_sec=2;
defaultParams.rms_long_min=5;
defaultParams.additional_buffer_sec = 1; %add this to the left and right of each event.

defaultParams.merge_within_sec = 5;

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
end

