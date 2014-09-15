%> @file
%> @brief Measures the magnitude square coherency between two input channels
%> The method internally calls MATLAB's mscohere function on individual blocks.
%======================================================================
%> @brief Calculates the magnitude squared coherency between two input channels
%> over consecutive epochs of standard duration (e.g. 30 s).  
%> @param data_cell Two element cell of equal lengthed psg 
%> vectors representing the channels to compare.
%> @param params A structure for variable parameters passed in
%> with following field
%> @li @c block_len_sec Duration of block in seconds to calculate power specrum from.
%> @param stageStruct Structure for stage information with following fields
%> @li @c standard_epoch_sec The duration of scored epochs in seconds (e.g.
%> 30)
%
%> @retval detectStruct a structure with following fields
%> @li @c new_data Copy of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. one per row).
%> @li @c paramStruct Structure with following fields which are each
%> vectors with the same number of elements as rows of new_events.  Each
%> field contains a measure of data in the range of the corrensponding
%> detection.
%> @li @c paramStruct.delta Delta band coherency [0.5, 4) Hz
%> @li @c paramStruct.theta Theta band coherency [4, 8) Hz
%> @li @c paramStruct.alpha Alpha band coherency [8, 12) Hz
%> @li @c paramStruct.sigma Sigma band coherency [12, 16) Hz
%> @li @c paramStruct.beta Beta band coherency [16, 30) Hz
%> @li @c paramStruct.gamma Gamma band coherency [30, Sample rate /2) Hz%
function detectStruct = detection_mscohere(data_cell, params, stageStruct)
% measures the magnitude square coherency between two input channels
% contained in data_cell (a two element cell of equal lengthed psg 
% vectors representing the channels to compare.  Method internally calls
% MATLAB's mscohere function on individual blocks.
                          

% written by Hyatt Moore IV, April 20, 2013
% July 22, 2013 - Updated to call mean instead of sum to keep normalized
% values across different size frequency bands.


% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.block_len_sec = 6;

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
    
    
    
    if(nargin==3 && ~isempty(stageStruct))
        standard_epoch_sec = stageStruct.standard_epoch_sec;
    else
        standard_epoch_sec = 30;
    end
    
    src_data = data_cell{1};
    ref_data = data_cell{2};
    samplerate = params.samplerate;
    
    filtsig = src_data;
    
    epoch_len = samplerate*standard_epoch_sec;
    num_epochs = floor(numel(filtsig)/(epoch_len));
    
    %we know the event boundaries in advance, so calculate as such.
    new_events = [1:epoch_len:num_epochs*epoch_len;epoch_len:epoch_len:(num_epochs)*epoch_len]';
    
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
    
    
    detectStruct.new_events = new_events;
    detectStruct.new_data = new_data*100; %show as a smooth percentage...
    detectStruct.paramStruct = paramStruct;
end
end