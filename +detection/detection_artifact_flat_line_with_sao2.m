%> @file
%> @brief Detects sections of data that have <i>flat lined</i> with loss of Oxygen saturation.
%======================================================================
%> @brief looks for occurrences of flat lining in the first input signal
%> withe additional requirement that the oxygen saturation (second input signal) is lost.
%> This detection method will search for indices when the saO2 channel is
%> below a set threshold (0.1 here)
%> A second pass is then conducted to determine if the primary channel is
%> below a given power threshold during this time.
%> if both criteria are met, then first pass saO2 channel detection is
%> registered as an event, otherwise it is not.
%> @param channel_data_cell A two element cell containing the signal data as column vectors.  
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c win_length_sec Window duration to calculate power from
%> @li @c win_interval_sec Interval in seconds to estimate power from
%> @li @c min_power Scalar value representing minimum power level allowed before flat line detection.
%> @saO2_min_pct Scalar value representing the minimum oxygen saturation as
%> a percent.
%
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data Data from first signal (i.e. channel_data_cell{1}).
%> @li @c .new_events A two column matrix of start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c .paramStruct Empty value returned (i.e. []).
%> @note global MARKING is used here for PSD settings @e removemean and
%> @e wintype.
function detectStruct = detection_artifact_flat_line_with_sao2(channel_data_cell,params,varargin)

%written Hyatt Moore IV
% modified: added varargin parameter
global MARKING;




% modified 9/15/2014 - streamline default parameter behavior.


pfile = strcat(mfilename('fullpath'),'.plist');

% set default parameters
defaultParams.win_length_sec = 5;
defaultParams.win_interval_sec = 5;
defaultParams.min_power = 0.1;
defaultParams.saO2_min_pct = 10; %this is 10%
        
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

    
    src_data = channel_data_cell{1};
    samplerate = params.samplerate;
    saO2_data = channel_data_cell{2};
    
    saO2_detections = thresholdcrossings(saO2_data<params.saO2_min_pct,0);
    num_detections = size(saO2_detections,1);
    second_pass_detections =  true(num_detections,1);
    
    win_length_sec = params.win_length_sec;
    win_interval_sec = params.win_interval_sec;
    
    PSD_settings.removemean = MARKING.SETTINGS.PSD.removemean;
    PSD_settings.interval = win_interval_sec;
    PSD_settings.FFT_window_sec=win_length_sec;
    PSD_settings.wintype = MARKING.SETTINGS.PSD.wintype;
    
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
    
end

