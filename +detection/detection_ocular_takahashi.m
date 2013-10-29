function detectStruct = detection_ocular_takahashi(data,varargin)
%detect eye movements from an EOG channel based on K. Takahashi's method as
%proposed in their paper:" Precise Measurement of Individual Rapid Eye
%Movement in REM Sleep of Humans"
%
%Step 1:  Smooth the data with an averaging filter (MA) - 7 taps
%Step 2:  identify points A and B as as consecutive min/max second
%derivaitave peaks
%Step 3:  If diff of A and B > threshold for amplitude, duration, and slope
%then it is an EM
%
%threshold criteria determined empirically by the authors of this paper as:
%Amplitude > 30 mV
%duration > 0.5 second
%slope > 248.3 uV/second

% implementation by Hyatt Moore
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input


%this allows direct input of parameters from outside function calls, which
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
        params.smoothing_filter_order = 10;
        params.thresh_ampl_uv = 30;
        params.thresh_dur_sec = 0.5; %maximum value here...
        params.thresh_slope = 248; %2.5 uv/sample -> 248uV/second
        params.merge_within_sec = 0.1;
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


maxPeaks = findpeaks(secondDeriv);

minPeaks = findpeaks(-secondDeriv);

n = min(numel(maxPeaks),numel(minPeaks));

if(maxPeaks(1)<=minPeaks(1))
    min_max_peaks = [maxPeaks(1:n),minPeaks(1:n)];
else
    min_max_peaks = [minPeaks(1:n),maxPeaks(1:n)];
end

min_max_peaks = sortrows(min_max_peaks);

% crucialPoints = findpeaks(abs(secondDeriv));
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