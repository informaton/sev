%> @file
%> @brief Eye movement detector based on I.S. Gopal and G.G.
%> Haddad's method proposed in "Automatic detection of eye movements in
%> REM sleep using the electrooculogram".  
%======================================================================
%> @brief Detects eye movements from an EOG channel based on I.S. Gopal and G.G.
%> Haddad's method as proposed in "Automatic detection of eye movements in
%> REM sleep using the electrooculogram".  The algorithm uses two rules,
%> along with modifications that classify eye movement wave forms (EMW) based
%> on two rules that are applied to decision points.  The decision points are
%> found at local maxima and minima and the rules check slope and amplitude
%> thresholds for classification as EMW or not.  
%>
%> @li Step 1: low pass filter to smooth the data - butterworth in paper
%> @li Step 2: obtain decision points from local maxima, minimia, and
%> modification of rule 1
%> @li Step 1:  Smooth the data with an averaging filter (MA) - 7 taps
%> @li Step 2:  identify points A and B as as consecutive min/max second
%> derivaitave peaks
%> @li Step 3:  If diff of A and B > threshold for amplitude, duration, and slope
%> then it is an EM
%
%> @note threshold criteria determined empirically by the authors of this paper as:
%> @note Amplitude > 30 mV
%> @note duration > 0.5 second
%> @note slope > 0.5 mV/second  (data is typically in uV here, so make it
%> uV)
%
%> @param data Sampled EOG signal as a column vector.  
%> @param params A structure for variable parameters passed in
%> with following fields  {default}
%> @li @c params.low_pass_filter_order Low pass filter order  {100}
%> @li @c params.low_pass_filter_freq_hz  Low pass filter frequency cutoff in Hz {8}
%> @li @c params.smooth_filter_order Smoothing filter order {7}
%> @li @c params.rule_1_thresh_slope Slope threshold {0.5}
%> @li @c params.rule_2_thresh_ampl_uv Amplitude threshold in uV {30}
%> @li @c params.rule_mf2_thresh_ampl_uv  Amplitude threshold in uV for rule 2 modification {10}
%> @li @c params.merge_within_sec Duration to merge consecutive events within {0.05}
%>
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Duplicate of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Structure with following field(s) which are vectors
%> with the same numer of elements as rows of @c new_events.
%> @li @c paramStruct.duration_sec Duration of detected eye movements in
%> seconds.
function detectStruct = detection_ocular_gopal(data,params,stageStruct)
%
% Implemented by  Hyat Moore IV
% modified 3/1/2013 - remove global references and use varargin

        
        
% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.low_pass_filter_order = 100;
defaultParams.low_pass_filter_freq_hz = 8;
defaultParams.smooth_filter_order = 7;
defaultParams.rule_1_thresh_slope = 0.5; %
defaultParams.rule_2_thresh_ampl_uv = 30;
defaultParams.rule_mf2_thresh_ampl_uv = 10;
%         defaultParams.thresh_dur_sec = 0.5;
defaultParams.merge_within_sec = 0.05;

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
    min_duration_sec = 0.3;
    
    
    %% 1.  low pass filter and smooth
    % - could also just try wavelet decomposition instead..
    
    % low pass filter
    lpf_params.order=params.low_pass_filter_order;
    lpf_params.freq_hz = params.low_pass_filter_freq_hz;
    lpf_params.samplerate = samplerate;
    data = filter.fir_lp(data,lpf_params);
    
    % smooth
    smooth_params.order=params.smooth_filter_order;
    smooth_params.abs = 0;
    data = filter.filter_ma(data,smooth_params);
    
    
    %% 2. obtain decision points/indices
    % the math below causes a single sample delay, which is accounted for by
    % the cat(0, ...) statement  (e.g diff([ 1 4 2])) produces [3 -2])
    % decision points are combination of local maxima and minima and indices
    % where |x(i)|>D and |x(i-1)|<D
    % the second amplitude threshold is from rule 2 modification (ref paper).
    d = diff(data); %first order difference
    absData = abs(data);
    decision_ind = find([0; [(d(1:end-1)./d(2:end)<=0);0] | ((absData(2:end)>params.rule_mf2_thresh_ampl_uv) & (absData(1:end-1)<params.rule_mf2_thresh_ampl_uv))]);
    
    %this also works, but not as elegant
    % p = sort([sev_findpeaks(x)-1,sev_findpeaks(-x)-1]);
    
    
    %% 3. apply rules to decision points
    %rule 1
    % dy = diff(data(decision_ind));
    dy = abs(diff(data(decision_ind)));
    dx = diff(decision_ind);
    
    %results are logical vectors that should be used as indices into
    %decision_ind vector which is a vector of sample indices into the EOG data
    %itself.
    dy_dx = dy./dx;
    rule2_result = cat(0,dy>params.rule_2_thresh_ampl_uv);
    rule1_result = cat(0,dy_dx > params.rule_1_thresh_slope);
    
    hypothesis1 = rule2_result & rule1_result;
    
    %apply rule 1 modificiation
    % for k=2:numel(hypothesis1)
    %     if(hypothesis1(k)&&hypothesis1(k-1))
    %         hypothesis1(k)=false;
    %     end
    % end
    
    
    %% 4. now make the events have a duration. -
    % this is not covered in the paper
    % but it seems a natural extension to include the rule 2 modficiation
    % amplitude threshold as a stopping requirement.
    new_events = decision_ind(hypothesis1);
    
    min_samples = ceil(params.merge_within_sec*samplerate);
    new_events = [new_events(:), min(new_events(:)+min_samples,numel(data))]; %give it the minimum duration
    paramStruct = [];
    % hypothesis_ind = find(hypothesis);
    for k=1:size(new_events,1)
        %     new_events(k,2) = decision_ind(hypothesis_ind(k)+1); %//pick up the next hypothesis index?
        %     new_events(k,
        while(absData(new_events(k,2))>params.rule_mf2_thresh_ampl_uv && new_events(k,2)<=numel(data))
            new_events(k,2) = new_events(k,2)+1;  %increase the sample one at a time until we get below the second threshold or reach the end of the data
        end
    end
    
    new_events = CLASS_events.merge_nearby_events(new_events,min_samples);
    if(~isempty(new_events))
        duration_sec = (new_events(:,2)-new_events(:,1)+1)/samplerate;
        new_events = new_events(duration_sec>min_duration_sec,:);
        paramStruct.duration_sec = duration_sec(duration_sec>min_duration_sec);
        
        %     numEvents = size(new_events,1);
        %     paramStruct.deltaY = zeros(numEvents,1);
        %     paramStruct.slope = zeros(numEvents,1);
        %     for k=1:numEvents
        %         paramStruct.dur_sec(k) = (new_events(k,2)-new_events(k,1)+1)/samplerate;
        %         paramStruct.deltaY(k) = data(new_events(k,2))-data(new_events(k,1));
        %         paramStruct.slope(k) = paramStruct.deltaY(k)/paramStruct.dur_sec(k);
        %     end
    else
        paramStruct = [];
    end
    
    detectStruct.new_data = data;
    detectStruct.new_events = new_events;
    detectStruct.paramStruct = paramStruct;
end