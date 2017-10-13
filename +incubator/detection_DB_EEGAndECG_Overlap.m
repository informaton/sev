function detectStruct = detection_DB_EEGAndECG_Overlap(channel_indices,optional_params)
%goal of this is to determine EEG and ECG activity in a window around
%scored leg movements as scored by a detector in the given database; which 
%is the Wisconsin Cohort in this case.  (Any event can be used in this
%detector however, it does not have to be leg movements).
%channel_indices(1) is EEG
%channel_indices(1) is ECG
%Author: Hyatt Moore IV
%Created: 9.26.2012

%relies on WORKSPACE global struct to get current filename and consequent
%.SCO data

global CHANNELS_CONTAINER;
global BATCH_PROCESS;
global MARKING;
global PSD;

openWSC(); %open the Wisconsin Database

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
        params.detectorID = 29; %the detector ID of the events to load in the database
        params.plus_minus_range_sec = 5; %plus minus range of interest
        params.min_offset2onset_separation_sec = 15; %minimum separation of respiratory events between offset to onset
        params.min_onset2offset_duration_sec = 2; %only include respiratory movements that are longer than this duration
        params.bin_size_sec = 0.5; %bin size to break the range of interest up into
        params.artifact_stage = 7; %designator for unknwown staging data
        plist.saveXMLPlist(pfile,params);
    end
end

if(isfield(BATCH_PROCESS,'stages_filename'))
    epoch_dur_sec = BATCH_PROCESS.standard_epoch_sec;
    patstudy = BATCH_PROCESS.stages_filename(1:end-4);
    
else
    epoch_dur_sec = MARKING.sev.standard_epoch_sec;
    patstudy = MARKING.sev.src_filename(1:end-4);
end

[PatID,StudyNum] = CLASS_events_container.getDB_PatientIdentifiers(patstudy);
q = mym('select patstudykey from studyinfo_t where patid="{S}" and studynum={Si}',PatID,StudyNum);
key = q.patstudykey;
stageStr = makeWhereInString([0,7],'numeric');
q = mym(sprintf('select start_sample, stop_sample, stage from events_t where detectorid=%u and patstudykey=%u and stage not in %s',params.detectorID,key,stageStr));
Evts = [q.start_sample,q.stop_sample];

numEvents = numel(Evts(:,1));
new_events = [];
cur_data = [];
EEG = [];
ECG = [];
if(numEvents>0)
    
    sample_rate = MARKING.sev.samplerate; 
    
    offsetEpochs = sample2epoch(Evts(:,2),epoch_dur_sec,sample_rate);
    onsetEpochs = sample2epoch(Evts(:,1),epoch_dur_sec,sample_rate);
    STAGES= MARKING.sev_STAGES;
    followingWakeStages = STAGES.line(offsetEpochs)==0|STAGES.line(offsetEpochs+1)==0;
    followingArtifactStages = STAGES.line(offsetEpochs)==params.artifact_stage|STAGES.line(offsetEpochs+1)==params.artifact_stage;
    previousWakeStages =  STAGES.line(onsetEpochs)==0|STAGES.line(offsetEpochs-1)==0;
    previousArtifactStages = STAGES.line(onsetEpochs)==params.artifact_stage|STAGES.line(onsetEpochs-1)==params.artifact_stage;
    Evts = Evts(~followingWakeStages&~previousWakeStages&~previousArtifactStages&~followingArtifactStages,:);
    
    plus_minus_range = params.plus_minus_range_sec*sample_rate;
    
    %ensure we stay within the boundaries of the data vector
    toolong = Evts(:,2)+plus_minus_range>MARKING.study_duration_in_samples(1);
    tooshort = Evts(:,1)-plus_minus_range<1;
    Evts = Evts(~toolong&~tooshort,:);
    
    aroundROI = [-plus_minus_range:-1,1:plus_minus_range];
    beforeROI = -plus_minus_range:-1;
    afterROI = 1:plus_minus_range;
    
    bin_size = params.bin_size_sec*sample_rate;
    
    numEvents = size(Evts,1);
    if(numEvents>0)
        
        if(~issorted(Evts(:,1)))
            [~,sort_i]=sort(Evts(:,1));
            Evts = Evts(sort_i,:);
        end
        
        if(params.first_event_only)
            numEvents = 1;
        end
        
        if(numEvents>1 && params.min_offset2onset_separation_sec>0)
            
            min_separation = params.min_offset2onset_separation_sec*sample_rate;
            offset2onset = Evts(2:end,1)-Evts(1:end-1,2);
            onset2offset = Evts(:,2)-Evts(:,1);
            too_short = onset2offset<params.min_onset2offset_duration_sec*sample_rate;
            skip = [0;offset2onset<min_separation]|[offset2onset<min_separation;0]|too_short;
            Evts = Evts(~skip,:);
            numEvents = sum(~skip);
        end
        
        nfft = PSD.FFT_window_sec*MARKING.sev.samplerate;
        num_freq_bins = ceil((nfft+1)/2);
        
        for k=1:numel(channel_indices)
            cur_data = CHANNELS_CONTAINER.getData(channel_indices(k));
            cur_samplerate = CHANNELS_CONTAINER.getSamplerate(channel_indices(k));
            
            power_beforeOnset = zeros(numEvents,num_freq_bins);
            power_afterOnset = zeros(numEvents,num_freq_bins);
            power_beforeOffset = zeros(numEvents,num_freq_bins);
            power_afterOffset = zeros(numEvents,num_freq_bins);
            
            amplitude_aroundOnset = zeros(numEvents,plus_minus_range*2);
            amplitude_aroundOffset = zeros(numEvents,plus_minus_range*2);            
            
            for r=1:numEvents
                power_beforeOnset(r,:) = mean(calcPSD(cur_data(beforeROI+Evts(r,1)),cur_samplerate,PSD),1);
                power_afterOnset(r,:) = mean(calcPSD(cur_data(afterROI+Evts(r,1)),cur_samplerate,PSD),1);
                power_beforeOffset(r,:) = mean(calcPSD(cur_data(beforeROI+Evts(r,2)),cur_samplerate,PSD),1);
                power_afterOffset(r,:) = mean(calcPSD(cur_data(afterROI+Evts(r,2)),cur_samplerate,PSD),1);                
                amplitude_aroundOnset(r,:) = cur_data(aroundROI+Evts(r,1));
                amplitude_aroundOffset(r,:) = cur_data(aroundROI+Evts(r,2));                
            end
            
            %sum down the columns- then reshape by taking every 50 columns of
            %the resulting row vector and placing in their own row.  The
            %result is the average amplitude per bin size blocks around
            %onset and offset of the selected event
            tmp.meanAmplitude_aroundOnset = mean(reshape(sum(abs(amplitude_aroundOnset),1),bin_size,[]))/numEvents;
            tmp.meanAmplitude_aroundOffset = mean(reshape(sum(abs(amplitude_aroundOffset),1),bin_size,[]))/numEvents;
            tmp.meanPower_beforeOnset = mean(power_beforeOnset,1);
            tmp.meanPower_afterOnset = mean(power_afterOnset,1);
            tmp.meanPower_beforeOffset = mean(power_beforeOffset,1);
            tmp.meanPower_afterOffset = mean(power_afterOffset,1);
            
            if(k==1)
                EEG = tmp;
            elseif(k==2)
                ECG = tmp;
            end
        end
        new_events=[1,plus_minus_range];
    end
end

detectStruct.new_events = new_events;
detectStruct.new_data = cur_data;
detectStruct.paramStruct.numEvents = numEvents;
detectStruct.paramStruct.EEG = EEG;
detectStruct.paramStruct.ECG = ECG;
