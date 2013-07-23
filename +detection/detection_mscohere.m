function detectStruct = detection_mscohere(data_cell, varargin)
%function detectStruct = detection_mscohere(data_cell, varargin)
% measures the magnitude square coherency between two input channels
% contained in data_cell (a two element cell of equal lengthed psg 
% vectors representing the channels to compare.  Method internally calls
% MATLAB's mscohere function on individual blocks.
                          

% written by Hyatt Moore IV, April 20, 2013
% July 22, 2013 - Updated to call mean instead of sum to keep normalized
% values across different size frequency bands.

if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else    
    pfile = strcat(mfilename('fullpath'),'.plist');

    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.block_len_sec = 6;
%        params.epoch_window_sec = 30; %the range to calculate the crosscorrelation over
%         params.cov_threshold = 0.4;
        plist.saveXMLPlist(pfile,params);
    end
end

if(nargin==3 && ~isempty(varargin{2}))
    standard_epoch_sec = varargin{2}.standard_epoch_sec;
else
    standard_epoch_sec = 30;
end

src_data = data_cell{1};
ref_data = data_cell{2};
samplerate = params.samplerate;
% block_len = params.block_len_sec*samplerate;
% range_len = block_len-1;

% filtsig = zeros(size(src_data));
filtsig = src_data;

epoch_len = samplerate*standard_epoch_sec;
num_epochs = floor(numel(filtsig)/(epoch_len));

%we know the event boundaries in advance, so calculate as such.
events = [1:epoch_len:num_epochs*epoch_len;epoch_len:epoch_len:(num_epochs)*epoch_len]';

%numBlocks = floor(numel(src_data)/block_len);


paramStruct.delta = zeros(num_epochs,1);
paramStruct.theta = zeros(num_epochs,1);
paramStruct.alpha = zeros(num_epochs,1);
paramStruct.sigma = zeros(num_epochs,1);
paramStruct.beta = zeros(num_epochs,1);
paramStruct.gamma = zeros(num_epochs,1);
new_data = zeros(numel(src_data),1);
window_name = @hamming;

nyquist_interval = 'onesided';
nfft = params.samplerate*params.block_len_sec;
window_vec = window_name(nfft);
noverlap = nfft/2;

% tic

for k=1:num_epochs
    start_k = (k-1)*epoch_len+1;
    epoch_range = start_k:start_k-1+epoch_len;

    [Cxy, freqs] = mscohere(src_data(epoch_range),ref_data(epoch_range),window_vec,noverlap,nfft,params.samplerate,nyquist_interval);

    paramStruct.delta(k) = mean(Cxy(freqs>=0.0&freqs<4)); %mean across the rows to produce a column vector
    paramStruct.theta(k) = mean(Cxy(freqs>=4&freqs<8)); %24 samples for 100Hz
    paramStruct.alpha(k) = mean(Cxy(freqs>=8&freqs<12));%24 samples for 100Hz
    paramStruct.sigma(k) = mean(Cxy(freqs>=12&freqs<16));%24 samples for 100Hz
    paramStruct.beta(k)  = mean(Cxy(freqs>=16&freqs<30)); %84
    paramStruct.gamma(k) = mean(Cxy(freqs>=30));  %121 samples for 100 hz
    
    %     coefficients(k) = mscohere(src_data(block_range),ref_data(block_range),window_vec,noverlap,params.samplerate,nyquist_interval);
   %                       coefficients(k) = xcov(src_data(block_range),ref_data(block_range),0,'coeff');
    new_data(epoch_range) = repmat(paramStruct.delta(k),epoch_len,1);
end

% toc

% paramStruct.delta(k) = sum(Cxy(:,freqs>=0.0&freqs<4),2); %mean across the rows to produce a column vector
%     paramStruct.theta(k) = sum(Cxy(:,freqs>=4&freqs<8),2);
%     paramStruct.alpha(k) = sum(Cxy(:,freqs>=8&freqs<12),2);
%     paramStruct.sigma(k) = sum(Cxy(:,freqs>=12&freqs<16),2);
%     paramStruct.beta(k)  = sum(Cxy(:,freqs>=16&freqs<30),2);
%     paramStruct.gamma(k) = sum(Cxy(:,freqs>=30),2);
    
    
% coefficients = mean(reshape(coefficients,paramStruct.epoch_window_sec/paramStruct.block_len_sec,[],1))'; %make it a row vector
                          

detectStruct.new_events = events;
% 
% lp_params.order=paramStruct.samplerate;
% lp_params.freq_hz = 1;
% lp_params.samplerate = paramStruct.samplerate;
% detectStruct.new_data = filter.fir_lp(new_data,lp_params)*100; %show as a smooth percentage...
detectStruct.new_data = new_data*100; %show as a smooth percentage...
detectStruct.paramStruct = paramStruct;