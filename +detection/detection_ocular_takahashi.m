%> @file
%> @brief Eye movement detector based on based on K. Takahashi et. al's method as
%> proposed in their paper:" Precise Measurement of Individual Rapid Eye
%> Movement in REM Sleep of Humans"
%======================================================================
%> @brief Detect eye movements from an EOG channel based on K. Takahashi's method as
%> proposed in their paper:" Precise Measurement of Individual Rapid Eye
%> Movement in REM Sleep of Humans"
%> Algorithm works as follows:
%> @li Step 1:  Smooth the data with an averaging filter (MA) - 7 taps
%> @li Step 2:  identify points A and B as as consecutive min/max second
%> derivaitave peaks
%> @li Step 3:  If diff of A and B > threshold for amplitude, duration, and slope
%> then it is an EM
%>
%> @note threshold criteria determined empirically by the authors of this paper as:
%> Amplitude > 30 mV
%> duration > 0.5 second
%> slope > 248.3 uV/second
%
%> @param data Sampled EOG signal as a column vector.  
%> @param params A structure for variable parameters passed in
%> with following fields  {default}
%> @li @c params.smoothing_filter_order Smoothing filter order  {10}
%> @li @c params.thresh_ampl_uv  Amplitude threshold in uV {30}
%> @li @c params.thresh_dur_sec  Maximum duration in seconds allowed for a detection {0.5} 
%> @li @c params.thresh_slope  Slope threshold to exceed {248} @note 2.5 uV/100 samples/sec -> 248uV/second
%> @li @c params.merge_within_sec  Duration to merge consecutive events within {0.1}
%
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Duplicate of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Structure with following field(s) which are vectors
%> with the same numer of elements as rows of @c new_events.
%> @li @c paramStruct.slope_uv_sec  Slope of the signal from event start to
%> finish
%> @li @c paramStruct.amplitude_uv Change in signal amplitude between start and stop of the event.
%> @li @c paramStruct.duration_sec Duration of detected eye movements in seconds.
function detectStruct = detection_ocular_takahashi(data,params,stageStruct)
% implementation by Hyatt Moore
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input



% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.smoothing_filter_order = 10;
defaultParams.thresh_ampl_uv = 30;
defaultParams.thresh_dur_sec = 0.5; %maximum value here...
defaultParams.thresh_slope = 248; %2.5 uv/sample -> 248uV/second
defaultParams.merge_within_sec = 0.1;

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
    % threshold.amplitude = 30;
    % threshold.duration = 0.5*sample_rate;
    % threshold.slope = 248.3/sample_rate;% (uV/second*(seconds/sample)) = uV/sample
    
    % %original method used smoothing filter on the order of seven taps
    % smooth
    smooth_params.order=params.smoothing_filter_order;
    smooth_params.rms = 0;
    smooth_data = filter.filter_ma(data,smooth_params);
    
    % num_taps = params.smoothing_filter_order;
    % if(num_taps>1)
    %     B = ones(num_taps,1)/num_taps;
    %     A = 1;
    %     smooth_data = filter(B,A,data);
    % else
    %     smooth_data = data; %do nothing
    % end
    
    
    
    % %low pass filter the data....
    % n = params.smoothing_filter_order;
    % delay = (n)/2;
    %
    % stop = 1.5;
    % b = fir1(n,stop/sample_rate*2,'low');
    %
    % smooth_data = filter(b,1,data);
    % % account for the delay...
    % smooth_data = [smooth_data((delay+1):end); zeros(delay,1)];
    %
    
    
    % instead, try a decomposition instead....
    % num_decompositions = 5;
    %
    % smooth_data = getEMD(data,num_decompositions);
    
    % fs = sample_rate;
    %padd a zero to account for the loss that occurs when using the diff
    %function
    
    
    
    % x = (1:numel(smooth_data))';
    
    % dx = 1/samplerate;
    % dx =1;
    
    
    differentiator_params.order=4;
    firstDeriv  = filter.filter_differentiator(data,differentiator_params);
    secondDeriv = filter.filter_differentiator(firstDeriv,differentiator_params);
    
    % firstDeriv = [0; diff(smooth_data)]/dx;
    %
    % secondDeriv =[0; diff(firstDeriv)]/dx;
    
    
    maxPeaks = sev_findpeaks(secondDeriv);
    
    minPeaks = sev_findpeaks(-secondDeriv);
    
    n = min(numel(maxPeaks),numel(minPeaks));
    
    if(maxPeaks(1)<=minPeaks(1))
        min_max_peaks = [maxPeaks(1:n),minPeaks(1:n)];
    else
        min_max_peaks = [minPeaks(1:n),maxPeaks(1:n)];
    end
    
    min_max_peaks = sortrows(min_max_peaks);
    
    % crucialPoints = sev_findpeaks(abs(secondDeriv));
    % min_max_peaks = [crucialPoints(1:end-1),crucialPoints(2:end)];
    
    thresh_dur = params.thresh_dur_sec*samplerate;
    thresh_slope = params.thresh_slope/samplerate;
    
    % min_samples = 0.05*samplerate; %check near within 5
    % min_max_peaks = CLASS_events.merge_nearby_events(min_max_peaks,min_samples);
    
    duration = min_max_peaks(:,2)-min_max_peaks(:,1)+1;
    amplitude = abs(data(min_max_peaks(:,2))-data(min_max_peaks(:,1)));
    slope = amplitude./duration;
    
    good_indices = (duration<thresh_dur) & (amplitude>params.thresh_ampl_uv) & (slope > thresh_slope);
    
    min_samples = params.merge_within_sec*samplerate;
    new_events = CLASS_events.merge_nearby_events(min_max_peaks(good_indices,:),min_samples);
    
    duration = new_events(:,2)-new_events(:,1)+1;
    amplitude = abs(data(new_events(:,2))-data(new_events(:,1)));
    slope = amplitude./duration;
    
    paramStruct.slope_uv_sec = slope;
    paramStruct.amplitude_uv = amplitude;
    paramStruct.duration_sec = duration;
    
    detectStruct.new_data = smooth_data;
    detectStruct.new_events = new_events;
    detectStruct.paramStruct = paramStruct;
end