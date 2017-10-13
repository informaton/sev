function detectStruct = detection_crosscorrelation(channel_index,optional_params)
global CHANNELS_CONTAINER;
%calculate the crosscorrelation (using xcorr) between two channels
% reshape?  
% OBJ_1 = CHANNELS_CONTAINER.cell_of_channels{channel_index(1)};
% OBJ_2 = CHANNELS_CONTAINER.cell_of_channels{channel_index(2)};
OBJ_1.data = CHANNELS_CONTAINER.getData(channel_index(1));
OBJ_1.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(1));
OBJ_2.data = CHANNELS_CONTAINER.getData(channel_index(2));
OBJ_2.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(2));
tic
% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_crosscorrelation.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.lag_sec = 1; %the amount of lag to calculate the crosscorrelation over
        params.window_sec = 2; %the range to calculate the crosscorrelation over
        %params.window_overlap_sec = 30; %frequency to overlap by...
        plist.saveXMLPlist(pfile,params);
    end
end

params.bias = 'coeff'; %options include {'biased','unbiased','none','coeff'}

window_len = params.window_sec*OBJ_1.sample_rate;
lag_len = params.lag_sec*OBJ_1.sample_rate;

% %% original way of doing this
% y = zeros(ceil(numel(OBJ_1.data)/window_len),1);
% 
% %break the events up to run continuously from window to window
% starts= (1:window_len:numel(OBJ_1.data))';
% stops = [starts(2:end);numel(OBJ_1.data)];
% new_events = [starts,stops]; 
% for k=1:numel(y)
%     ind = starts(k):stops(k);
%     y(k) = max(abs(xcorr(OBJ_1.data(ind),OBJ_2.data(ind),lag_len,params.bias)));
% end

%% later way of doing this
y = zeros(size(OBJ_1.data));
range = 1:lag_len;
starts= (1:window_len:numel(OBJ_1.data))';
stops = [starts(2:end);numel(OBJ_1.data)];
new_events = [starts,stops]; 
for k=ceil(lag_len/2):floor(numel(y)-lag_len/2)
   y(k) = xcov(OBJ_1.data(range),OBJ_2.data(range),0,params.bias); 
end

%% output
detectStruct.new_events = new_events;
detectStruct.new_data = y;
% detectStruct.paramStruct.max_xcorr = y;
disp 'detection_crosscorrelation.m'
toc