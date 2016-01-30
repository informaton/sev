function detectStruct = detection_artifact_breathing(channel_indices, optional_params)
%breathing artifact detector by way of cross covariance method
%channel_indices(1) is the source channel that is contaminated with
%artifact
%channel_indices(2) is the reference channel causing the artifact
% written by Hyatt Moore IV, April 4, 2012

global CHANNELS_CONTAINER;
src_data = CHANNELS_CONTAINER.getData(channel_indices(1));
ref_data = CHANNELS_CONTAINER.getData(channel_indices(2));
sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else    
%     pfile = '+detection/detection_artifact_breathing.plist';
    pfile =  strcat(mfilename('fullpath'),'.plist');
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
%         params.lag_sec = 1; %the amount of lag to calculate the crosscorrelation over
        params.window_sec = 30; %the range to calculate the crosscorrelation over
        params.cov_threshold = 0.4;
        plist.saveXMLPlist(pfile,params);
    end
end

tic

block_len = params.window_sec*sample_rate;
range_len = block_len-1;
filtsig = src_data;
numBlocks = floor(numel(src_data)/block_len);
coefficients = zeros(numBlocks,1);
events = ones(numBlocks,2);
% for k=1:block_len:numel(src_data)-block_len+1
for k=1:numBlocks
    start_k = (k-1)*block_len+1;
%     block_range = k:k+range_len;
    block_range = start_k:start_k+range_len;
    events(k,:) = [block_range(1),block_range(end)];
    coefficients(k) = xcov(src_data(block_range),ref_data(block_range),0,'coeff');
    filtsig(block_range) =  coefficients(k);
%     filtsig(block_range) = xcov(src_data(block_range),ref_data(block_range),0,'coeff');
end

toc
% detectStruct.new_events = thresholdcrossings(abs(filtsig),params.cov_threshold);
% detectStruct.new_data = filtsig*100;
% detectStruct.paramStruct.coefficients = abs(detectStruct.new_data(detectStruct.new_events(:,1))); %retain the xcov coefficient value at this point.
detectStruct.new_events = events;
detectStruct.new_data = filtsig*100;
detectStruct.paramStruct.coefficients = coefficients;
