function detectStruct = detection_channelCorrel(channel_indices, optional_params)
%breathing artifact detector by way of cross covariance method
%channel_indices(1) is the source channel that is contaminated with
%artifact
%channel_indices(2:end) are reference channels being compared
% xcov(c3,sao2,0,'coeff') is computed as follows:
% sum((c3-mean(c3)).*(sao2-mean(sao2)))/sqrt(sum((c3-mean(c3)).^2)*sum((sao2-mean(sao2)).^2))
%
% written by Hyatt Moore IV, April 4, 2012
% modified: July, 11, 2012
% modified: September 11, 2012 - removed the batch processing channel and
% only handle one channel at a time to keep with SEV design

global CHANNELS_CONTAINER;
src_index = channel_indices(1);
ref_index = channel_indices(2);
src_data = CHANNELS_CONTAINER.getData(src_index);
sample_rate = CHANNELS_CONTAINER.get_sample_rate(src_index);

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else    
    pfile = strcat(mfilename('fullpath'),'.plist');

    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.block_len_sec = 5;
        params.epoch_window_sec = 30; %the range to calculate the crosscorrelation over
%         params.cov_threshold = 0.4;
        plist.saveXMLPlist(pfile,params);
    end
end

block_len = params.block_len_sec*sample_rate;
range_len = block_len-1;

% filtsig = zeros(size(src_data));
filtsig = src_data;
window_len = sample_rate*params.epoch_window_sec;
num_epochs = floor(numel(filtsig)/(window_len));

%we know the event boundaries in advance, so calculate as such.
events = [1:window_len:num_epochs*window_len;window_len:window_len:(num_epochs)*window_len]';

numBlocks = floor(numel(src_data)/block_len);
% ch_labels = regexprep(CHANNELS_CONTAINER.get_labels(),'-|\s|/|\\',''); %make labels that can work as structure field names



ref_data = CHANNELS_CONTAINER.cell_of_channels{ref_index}.raw_data;
coefficients = zeros(numBlocks,1);
%     events = ones(numBlocks,2);

% for k=1:block_len:numel(src_data)-block_len+1

for k=1:numBlocks
    start_k = (k-1)*block_len+1;
    block_range = start_k:start_k+range_len;
    coefficients(k) = xcov(src_data(block_range),ref_data(block_range),0,'coeff');
    
    %old code:
    %     block_range = k:k+range_len;
    %         events(k,:) = [block_range(1),block_range(end)];
    %         filtsig(block_range) =  coefficients(k);
    %     filtsig(block_range) = xcov(src_data(block_range),ref_data(block_range),0,'coeff');
end

coefficients = mean(reshape(coefficients,params.epoch_window_sec/params.block_len_sec,[],1))'; %make it a row vector
paramStruct.r_value = coefficients;
% paramStruct.(ch_labels{ref_index}) = coefficients;


% detectStruct.new_events = thresholdcrossings(abs(filtsig),params.cov_threshold);
% detectStruct.new_data = filtsig*100;
% detectStruct.paramStruct.coefficients = abs(detectStruct.new_data(detectStruct.new_events(:,1))); %retain the xcov coefficient value at this point.
detectStruct.new_events = events;
detectStruct.new_data = filtsig*100; %make it a percentage...
detectStruct.paramStruct = paramStruct;