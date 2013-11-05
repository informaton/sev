%> @file
%> @brief Calculates the power spectrum of input channel data.
%======================================================================
%> @brief Calculates the power spectrum of input channel data over the
%> standard epoch duration (e.g. 30 s)
%> @param signal_data
%> @param params A structure for variable parameters passed in
%> with following field
%> @li @c block_len_sec Duration of block in seconds to calculate power specrum from.
%> @param stageStruct Structure for stage information with following fields
%> @li @c standard_epoch_sec Epoch duration in seconds (e.g. 30)
%
%> @param PSD_settings <i>optional</i>
%> @retval detectStruct a structure with following fields
%> @li @c new_data Copy of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. one per row).
%> @li @c paramStruct Structure with following fields which are each
%> vectors with the same number of elements as rows of new_events.  Each
%> field contains a measure of data in the range of the corrensponding
%> detection.
%> @li @c paramStruct.delta Delta band power [0.5, 4) Hz
%> @li @c paramStruct.theta Theta band power [4, 8) Hz
%> @li @c paramStruct.alpha Alpha band power [8, 12) Hz
%> @li @c paramStruct.sigma Sigma band power [12, 16) Hz
%> @li @c paramStruct.beta Beta band power [16, 30) Hz
%> @li @c paramStruct.gamma Gamma band power [30, Sample rate /2) Hz
%
%> @note global MARKING is used here for PSD settings @e removemean and
%> @e wintype.
function detectStruct = detection_psd(signal_data, params, stageStruct,optional_PSD_settings)
% written by Hyatt Moore IV, July 28, 2013

global MARKING;

if(nargin<2 || isempty(params))    
    pfile = strcat(mfilename('fullpath'),'.plist');

    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.block_len_sec = 6;
        %        params.epoch_window_sec = 30; %the range to calculate the crosscorrelation over
        plist.saveXMLPlist(pfile,params);
    end
end

if(nargin==3 && ~isempty(stageStruct))
    standard_epoch_sec = stageStruct.standard_epoch_sec;
else
    standard_epoch_sec = 30;
end

samplerate = params.samplerate;


if(nargin<4)
    PSD_settings = MARKING.SETTINGS.PSD;
else
    PSD_settings = optional_PSD_settings;
end

epoch_len = samplerate*standard_epoch_sec;
num_epochs = floor(numel(signal_data)/(epoch_len));
periodograms_per_epoch = floor(standard_epoch_sec/PSD_settings.interval);

%we know the event boundaries in advance, so calculate as such.
eventMatrix = [1:epoch_len:num_epochs*epoch_len;epoch_len:epoch_len:(num_epochs)*epoch_len]';

% E = 1:num_epochs;
% S = stageStruct.line(E);

%numBlocks = floor(numel(src_data)/block_len);

paramStruct.delta = zeros(num_epochs,1);
paramStruct.theta = zeros(num_epochs,1);
paramStruct.alpha = zeros(num_epochs,1);
paramStruct.sigma = zeros(num_epochs,1);
paramStruct.beta = zeros(num_epochs,1);
paramStruct.gamma = zeros(num_epochs,1);

[Cxx freqs nfft] = calcPSD(signal_data,params.samplerate,PSD_settings);

delta = sum(Cxx(:,freqs>=0.5&freqs<4),2); %mean across the rows to produce a column vector
theta = sum(Cxx(:,freqs>=4&freqs<8),2);
alpha = sum(Cxx(:,freqs>=8&freqs<12),2);
sigma = sum(Cxx(:,freqs>=12&freqs<16),2);
beta  = sum(Cxx(:,freqs>=16&freqs<30),2);
gamma = sum(Cxx(:,freqs>=30),2);
new_data = zeros(size(signal_data));
tic
for k=1:num_epochs
    start_p = (k-1)*periodograms_per_epoch+1;
    epoch_range = start_p:start_p-1+periodograms_per_epoch;
    
    start_k = (k-1)*epoch_len+1;
    epoch_samples_range = start_k:start_k-1+epoch_len;

    paramStruct.delta(k) = mean(delta(epoch_range)); %mean across the rows to produce a column vector
    paramStruct.theta(k) = mean(theta(epoch_range)); %24 samples for 100Hz
    paramStruct.alpha(k) = mean(alpha(epoch_range));%24 samples for 100Hz
    paramStruct.sigma(k) = mean(sigma(epoch_range));%24 samples for 100Hz
    paramStruct.beta(k)  = mean(beta(epoch_range)); %84
    paramStruct.gamma(k) = mean(gamma(epoch_range));  %121 samples for 100 hz
    new_data(epoch_samples_range) = repmat(paramStruct.delta(k),epoch_len,1);
end
toc
% coefficients = mean(reshape(coefficients,paramStruct.epoch_window_sec/paramStruct.block_len_sec,[],1))'; %make it a row vector
                          
detectStruct.new_events = eventMatrix;
% 
% lp_params.order=paramStruct.samplerate;
% lp_params.freq_hz = 1;
% lp_params.samplerate = paramStruct.samplerate;
% detectStruct.new_data = filter.fir_lp(new_data,lp_params)*100; %show as a smooth percentage...
detectStruct.new_data = new_data; %show as a smooth percentage...
detectStruct.paramStruct = paramStruct;

end
