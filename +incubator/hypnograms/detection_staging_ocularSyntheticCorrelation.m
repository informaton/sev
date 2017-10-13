function detectStruct = detection_staging_ocularSyntheticCorrelation(channel_index,optional_params)
global CHANNELS_CONTAINER;
%stage sleep based on slope after first synthesizing channels to each other

OBJ_1.data = filter.adaptive_synth_rls(channel_index(1),channel_index(2));
% OBJ_1.data = filter.anc_rls(channel_index(1),channel_index(2));
OBJ_1.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(1));
OBJ_2.data = filter.adaptive_synth_rls(channel_index(2),channel_index(1));
% OBJ_2.data = filter.anc_rls(channel_index(2),channel_index(1));
OBJ_2.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(2));

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    mfile = mfilename('fullpath');
    pfile = strcat(mfile,'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.epoch_sec = 30; %size of epoch to stage data on
        params.artifact_stage = 7; %designator for unknwown staging data
        plist.saveXMLPlist(pfile,params);
    end
end

window_len = params.epoch_sec*OBJ_1.sample_rate;

stages = ones(ceil(numel(OBJ_1.data)/window_len),1)*7;
slopes = zeros(ceil(numel(OBJ_1.data)/window_len),1);

starts= (1:window_len:numel(OBJ_1.data))';
stops = [starts(2:end)-1;numel(OBJ_1.data)];
new_events = [starts,stops]; 

crosscorr = cumsum(OBJ_1.data.*OBJ_2.data);
x = (1:window_len)';
for k=1:numel(stages)
    ind = starts(k):stops(k);
    y = crosscorr(ind);
    m_b = polyfit(x,y,1);
    slopes(k) = m_b(1);
    if(slopes(k)<0)
        stages(k) = 5;
    else
        stages(k) = 1;
    end
    
end

detectStruct.new_events = new_events;
detectStruct.new_data = OBJ_1.data;
detectStruct.paramStruct.stages = stages;
detectStruct.paramStruct.correlation_slope = slopes;
