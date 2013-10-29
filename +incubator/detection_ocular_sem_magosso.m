function detectStruct = detection_ocular_sem_magosso(source_index,optional_params)
%detect slow eye movements from an EOG channel based on Elisa Magosso's
%paper, "A wavelet based method for automatic detection of slow eye
%movements: A pilot study".
%
% Description: The algorithm is based on a wavelet analysis of difference
% between right and left EOG tracings and has three steps:
%
% Step 1: Wavelet decomposition (to 10 levels) using db4 wavelet
% Step 2: Compute energy in 0.5s time steps
% Step 3: Comapare energy of high scale details against both high and low scale
% details


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
        params.wavelet_levels = 10; %10 is default in paper
        params.energy_thresh_pct = 0.85;
        params.merge_within_sec = 0.05;
        params.min_dur_sec = 1.0; %must be at least 1 second long
        plist.saveXMLPlist(pfile,params);
    end
end

%determine if using one/same EOG channel or two/different EOG channels
if(source_index(1)==source_index(2))
   data = 2*CHANNELS_CONTAINER.getData(source_index(1));
else
   data = CHANNELS_CONTAINER.getData(source_index(1))-CHANNELS_CONTAINER.getData(source_index(2));
end

sample_rate = CHANNELS_CONTAINER.getSamplerate(source_index(1));

%% Step 1: Wavelet decomposition
wname = 'db4';
% [Coef_o,Levels] = wavedec(data,params.num_levels,wname);
len = numel(data);
pow = 2^params.wavelet_levels;

%zeropad if necessary to get power of two length data necessary for
%wavelets
if rem(len,pow)>0
    sOK = ceil(len/pow)*pow;
    data = [data(:);zeros(sOK-len,1)];
end



swc = swt(data,params.wavelet_levels, wname); %swc size is N+1 x (numel(data)) 
%swc(N+1,:) = approximation for level N
%swc(i,:) = details for level i level 1 is associated with 25-50Hz for
%fs=100hz

%don't want to consider high frequency levels here ... so toss out details
%1 and 2, 3, which are 6.25-50Hz for fs = 100Hz.
energy_weights = [0
    0;
    0.5115; %from paper
    1.0431;
    1.0761;
    0;
    0.0988;
    0.1553;
    0.04888
    0.0496]'; %transpose this to get a row vector for products below

% energy_weights = ones(1,10);
%1xK * KxD = 1xD
energy_low_freq =  energy_weights(7:10)*swc(7:10,:).^2;%are higher decomposition levels...
energy_high_freq = energy_weights(4:5)*swc(4:5,:).^2;%are lower decomposition levels

energy_discriminator_func = energy_low_freq./(energy_low_freq+energy_high_freq);
new_events = thresholdcrossings(energy_discriminator_func,params.energy_thresh_pct);

merge_within_samples = params.merge_within_sec*sample_rate;
new_events = CLASS_events.merge_nearby_events(new_events,merge_within_samples);

min_samples = params.min_dur_sec*sample_rate;
new_events = CLASS_events.cleanup_events(new_events,min_samples);

%reject those less than 1.0 second


% [wd, wl] = waverec(data,params.num_levels,wname);
% 
% 
% w_ind = cumsum(1;wl(1:end-1)); 
% 
% %smoothed energy
% energy = wd.^2;

% %book keeping is as follows
% w_ind(1):w_ind(1+1)-1 = app Coef.(N) (wl(1)) = length of app. coeff(N)
% w_ind(2):w_ind(3)-1 = detail Coeff(N)
% w_ind(3):w_ind(4)-1 = detail Coeff(N-1)
% ...
% w_ind(i):w_ind(i+1)-1 = detail Coeff(N-i+2) for i = 2:N in this case




% %adjust zero-padding as necessary
% if rem(len,pow)>0
%     filtsig  = filtsig(1:len);
% end
if(~isempty(new_events))
    new_events(new_events(:,2)>=numel(data),:)=[]; %remove any events outside of the data's range
end

detectStruct.new_data = data;
detectStruct.new_events = new_events;
detectStruct.paramStruct = [];