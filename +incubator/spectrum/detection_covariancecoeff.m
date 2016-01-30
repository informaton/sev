function detectStruct = detection_covariancecoeff(channel_index,optional_params)
global CHANNELS_CONTAINER;
%calculate the correlation coefficient using covariance
% OBJ_1 = CHANNELS_CONTAINER.cell_of_channels{channel_index(1)};
% OBJ_2 = CHANNELS_CONTAINER.cell_of_channels{channel_index(2)};

OBJ_1.data = CHANNELS_CONTAINER.getData(channel_index(1));
OBJ_1.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(1));
OBJ_2.data = CHANNELS_CONTAINER.getData(channel_index(2));
OBJ_2.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(2));


% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = '+detection/detection_covariancecoeff.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        
        params.lag_sec = 2; %the amount of lag to calculate the covariance over
        params.window_sec = 30; %the range to calculate the covariance over
        %params.window_overlap_sec = 30; %frequency to overlap by...
        plist.saveXMLPlist(pfile,params);
    end
end

window_len = params.window_sec*OBJ_1.sample_rate;
lag_len = params.lag_sec*OBJ_1.sample_rate;
y = zeros(ceil(numel(OBJ_1.data)/window_len),1);

%break the events up to run continuously from window to window
starts= (1:window_len:numel(OBJ_1.data))';
stops = [starts(2:end);numel(OBJ_1.data)];
new_events = [starts,stops]; 
for k=1:numel(y)
    ind = starts(k):stops(k);
    y(k) = corrcoef(OBJ_1.data(ind),OBJ_2.data(ind));
end

detectStruct.new_events = new_events;
detectStruct.new_data = OBJ_1.data;
detectStruct.paramStruct.max_xcorr = y;