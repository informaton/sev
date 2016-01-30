function detectStruct = detection_SCO_respiratoryLegOverlap(channel_index,optional_params)
%goal of this is to determine leg muscle activity in a window around
%respiratory events as scored in the Wisconsin Sleep Cohort.
%primarily interested in the activity at the end of respiratory events, but
%we will look at both before and after
%
%relies on WORKSPACE global struct to get current filename and consequent
%.SCO data
global CHANNELS_CONTAINER;
global WORKSPACE;
global BATCH_PROCESS;
global STAGES;
global DEFAULTS;

if(isfield(BATCH_PROCESS,'stages_filename'))
    epoch_dur_sec = BATCH_PROCESS.standard_epoch_sec;
    sco_filename = fullfile(strrep(BATCH_PROCESS.stages_filename,'STA','SCO'));
else
    epoch_dur_sec = DEFAULTS.standard_epoch_sec;
    sco_filename = fullfile(WORKSPACE.cur_pathname,strrep(WORKSPACE.cur_filename,'EDF','SCO'));
end

SCO = loadSCOfile(sco_filename);
%SCO is a struct with the fields
% .epoch - the epoch that the scored event occured in
% .start_stop_matrix - the sample point that the events begin and end on
% .label - the string label used to describe the event

if(~isempty(SCO))
    respLabels = {'Hypopnea','Obs Apnea','Mixed Apnea', 'Central Apnea'};
    respInd = false(size(SCO.epoch));
    for r=1:numel(respLabels)
       respInd = respInd|strcmpi(respLabels{r},SCO.label); 
    end
    respEvts = SCO.start_stop_matrix(respInd,:);
else
    respEvts = [];
end

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
        params.first_event_only = 0; %if 1 then only take activity from the first event
        params.plus_minus_range_sec = 5; %plus minus range of interest
        params.min_offset2onset_separation_sec = 30; %minimum separation of respiratory events between offset to onset
        params.min_onset2offset_duration_sec = 15; %only include respiratory movements that are longer than this duration
        params.bin_size_sec = 0.5; %bin size to break the range of interest up into
        params.artifact_stage = 7; %designator for unknwown staging data
        plist.saveXMLPlist(pfile,params);
    end
end

numRespEvents = numel(respEvts(:,1));
new_events = [];
LMbefore = [];
LMafter = [];
data = [];
respOffset2OnsetInterval = 0;
respEventDurSec = 0;
if(numRespEvents>0)
    
    data = CHANNELS_CONTAINER.getData(channel_index(1));
    sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index(1));
    
    respOffsetEpochs = sample2epoch(respEvts(:,2),epoch_dur_sec,sample_rate);
    respOnsetEpochs = sample2epoch(respEvts(:,1),epoch_dur_sec,sample_rate);
    followingWakeStages = STAGES.line(respOffsetEpochs)==0|STAGES.line(respOffsetEpochs+1)==0;
    followingArtifactStages = STAGES.line(respOffsetEpochs)==params.artifact_stage|STAGES.line(respOffsetEpochs+1)==params.artifact_stage;
    previousWakeStages =  STAGES.line(respOnsetEpochs)==0|STAGES.line(respOffsetEpochs-1)==0;
    previousArtifactStages = STAGES.line(respOnsetEpochs)==params.artifact_stage|STAGES.line(respOnsetEpochs-1)==params.artifact_stage;
    respEvts = respEvts(~followingWakeStages&~previousWakeStages&~previousArtifactStages&~followingArtifactStages,:);
    
    plus_minus_range = params.plus_minus_range_sec*sample_rate;
    
    toolong = respEvts(:,2)+plus_minus_range>numel(data);
    tooshort = respEvts(:,1)-plus_minus_range<1;
    respEvts = respEvts(~toolong&~tooshort,:);
    
    ROI = [-plus_minus_range:-1,1:plus_minus_range];
    bin_size = params.bin_size_sec*sample_rate;
    
    numRespEvents = size(respEvts,1);
    if(numRespEvents>0)
        if(~issorted(respEvts(:,1)))
           [~,sort_i]=sort(respEvts(:,1));
           respEvts = respEvts(sort_i,:);
        end
        if(params.first_event_only)
            numRespEvents = 1;
        end
        if(numRespEvents>1 && params.min_offset2onset_separation_sec>0)
            min_separation = params.min_offset2onset_separation_sec*sample_rate;
            offset2onset = respEvts(2:end,1)-respEvts(1:end-1,2);
            onset2offset = respEvts(:,2)-respEvts(:,1);
            too_short = onset2offset<params.min_onset2offset_duration_sec*sample_rate;
            skip = [0;offset2onset<min_separation]|[offset2onset<min_separation;0]|too_short;
            respEvts = respEvts(~skip,:);
            numRespEvents = sum(~skip);
        end
        if(numRespEvents>1)
            respOffset2OnsetInterval = mean(respEvts(2:end,1)-respEvts(1:end-1,2));
        end
        
        respEventDurSec = mean((respEvts(:,2)-respEvts(:,1))/sample_rate);
        beforeActivity = zeros(numRespEvents,plus_minus_range*2);
        afterActivity = zeros(numRespEvents,plus_minus_range*2);
        
        for r=1:numRespEvents
            beforeActivity(r,:) = data(ROI+respEvts(r,1));
            afterActivity(r,:) = data(ROI+respEvts(r,2));
        end
        
        %sum down the columns- then reshape by taking every 50 columns of
        %the resulting row vector and placing in their own row.  The
        %average
        LMbefore = mean(reshape(sum(abs(beforeActivity),1),bin_size,[]))/numRespEvents;
%         LMbeforeMean = mean(reshape(mean(abs(beforeActivity),1),bin_size,[]),1);
%         LMbeforeBin = mean(reshape(sum(abs(beforeActivity),1),bin_size,[]))/bin_size;
%         LMbeforeAvg = mean(reshape(sum(abs(beforeActivity),1),bin_size,[])/numRespEvents);
        LMafter = mean(reshape(sum(abs(afterActivity),1),bin_size,[]))/numRespEvents;
        new_events=[1,plus_minus_range];
    end
end

detectStruct.new_events = new_events;
detectStruct.new_data = data;
detectStruct.paramStruct.respEventsCount = numRespEvents;
detectStruct.paramStruct.respOffsetToOnsetIntervalSec = respOffset2OnsetInterval/sample_rate;
detectStruct.paramStruct.respEventDurationSec = respEventDurSec;
detectStruct.paramStruct.LegAroundRespiratoryEventStart = LMbefore;
detectStruct.paramStruct.LegAroundRespiratoryEventEnd = LMafter;