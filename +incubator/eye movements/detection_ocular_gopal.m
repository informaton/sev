function detectStruct = detection_ocular_gopal(source_index,optional_params)
%detect eye movements from an EOG channel based on I.S. Gopal and G.G.
%Haddad's method as proposed in "Automatic detection of eye movements in
%REM sleep using the electrooculogram".  The algorithm uses two rules,
%along with modifications that classify eye movement wave forms (EMW) based
%on two rules that are applied to decision points.  The decision points are
%found at local maxima and minima and the rules check slope and amplitude
%thresholds for classification as EMW or not.  
%
% Step 1: low pass filter to smooth the data - butterworth in paper
% Step 2: obtain decision points from local maxima, minimia, and
% modification of rule 1

%Step 1:  Smooth the data with an averaging filter (MA) - 7 taps
%Step 2:  identify points A and B as as consecutive min/max second
%derivaitave peaks
%Step 3:  If diff of A and B > threshold for amplitude, duration, and slope
%then it is an EM
%
%threshold criteria determined empirically by the authors of this paper as:
%Amplitude > 30 mV
%duration > 0.5 second
%slope > 248.3 mV/second

global CHANNELS_CONTAINER;
tic
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.low_pass_filter_order = 100;
        params.low_pass_filter_freq_hz = 8;
        params.smooth_filter_order = 3;
        params.rule_1_thresh_slope = 0.25;
        params.rule_2_thresh_ampl_uv = 30;
        params.rule_mf2_thresh_ampl_uv = 10;
%         params.thresh_dur_sec = 0.5;
        params.merge_within_sec = 0.05;
        plist.saveXMLPlist(pfile,params);
    end
end

sample_rate = CHANNELS_CONTAINER.getSamplerate(source_index);


%% 1.  low pass filter and smooth 
% - could also just try wavelet decomposition instead..

% low pass filter
lpf_params.order=params.low_pass_filter_order;
lpf_params.freq_hz = params.low_pass_filter_freq_hz;
data = filter.fir_lp(source_index,lpf_params);
        
% smooth
smooth_params.order=10;
smooth_params.rms = 0;
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
% p = sort([findpeaks(x)-1,findpeaks(-x)-1]); 


%% 3. apply rules to decision points
%rule 1
dy = diff(data(decision_ind));
dx = diff(decision_ind);

%results are logical vectors that should be used as indices into
%decision_ind vector which is a vector of sample indices into the EOG data
%itself.
rule2_result = cat(0,dy>params.rule_2_thresh_ampl_uv);
rule1_result = cat(0,dy./dx > params.rule_1_thresh_slope);

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

min_samples = ceil(params.merge_within_sec*sample_rate);
new_events = [new_events(:), min(new_events(:)+min_samples,numel(data))]; %give it the minimum duration
toc
% hypothesis_ind = find(hypothesis);
for k=1:size(new_events,1)
%     new_events(k,2) = decision_ind(hypothesis_ind(k)+1); %//pick up the next hypothesis index? 
%     new_events(k,
    while(absData(new_events(k,2))>params.rule_mf2_thresh_ampl_uv && new_events(k,2)<=numel(data))
        new_events(k,2) = new_events(k,2)+1;  %increase the sample one at a time until we get below the second threshold or reach the end of the data
    end
end
new_events = CLASS_events.merge_nearby_events(new_events,min_samples);
detectStruct.new_data = data;
detectStruct.new_events = new_events;
detectStruct.paramStruct = [];
toc
