function [localCHANNELS_CONTAINER, localBATCH_PROCESS, studyInfo] = load_file(pathname,filename,localBATCH_PROCESS)
%This function loads individual files for batch processing
%
%pathname and filename are for the directory containing EDF file(s) to load
%channel_labels2load is a cell containing character strings of the labels
%of the EDF which should be loaded.  Non-unique values will be referenced
%to the same index of the channel that was loaded into
%CHANNELS_CONTAINER
%class_channel_indices are the indices into CHANNELS_CONTAINER for
%which the corresponding channel_labels2load were loaded into.
%
%10.9.12 - removed references to global WORKSPACE, and use MARKING instead
%modified on 10.3.2012 - passing CHANNELS_CONTAINER as a variable now
%last edit: 9.26.2012 - added number_of_epochs field to WORKSPACE
%last modified 9 May, 2011

%Author: hyatt moore iv

%studyInfo is a struct wih these definitions:
% studyInfo.startDateTime = HDR.T0;
% studyInfo.study_duration_in_seconds = HDR.duration_sec;
% studyInfo.study_duration_in_samples = HDR.duration_samples;
% studyInfo.num_epochs = floor(HDR.duration_sec/BATCH_PROCESS.standard_epoch_sec);

%HDR is a struct that contains the header data found in the EDF
HDR = loadEDF(fullfile(pathname,filename));

%ONLY LOAD SINGLE INSTANCE OF REQUESTED CHANNEL LABELS - there could be
%multiple requests for the same channel, and it would be wasteful to load
%them repeatedly rather than have each request be referenced to a single
%instance of the channel in memory
localBATCH_PROCESS = verify_synthetic_channel_usage(localBATCH_PROCESS);

max_HDR_labels = numel(HDR.label);
num_synth_channels = numel(localBATCH_PROCESS.synth_CHANNEL.names);

if(num_synth_channels>0)
    EDF_indices2load = num2cell((1:num_synth_channels)'+numel(HDR.label));
else
    EDF_indices2load = {};
end
HDR.label = [HDR.label;localBATCH_PROCESS.synth_CHANNEL.names];



[localBATCH_PROCESS.synth_CHANNEL.settings_lite, EDF_indices2load] = getChannelIndices(localBATCH_PROCESS.synth_CHANNEL.settings_lite,EDF_indices2load,HDR.label);

[localBATCH_PROCESS.artifact_settings, EDF_indices2load] = getChannelIndices(localBATCH_PROCESS.artifact_settings,EDF_indices2load,HDR.label);

[localBATCH_PROCESS.event_settings, EDF_indices2load] = getChannelIndices(localBATCH_PROCESS.event_settings,EDF_indices2load,HDR.label);

[localBATCH_PROCESS.PSD_settings, EDF_indices2load] = getChannelIndices(localBATCH_PROCESS.PSD_settings,EDF_indices2load,HDR.label);

[localBATCH_PROCESS.MUSIC_settings, EDF_indices2load] = getChannelIndices(localBATCH_PROCESS.MUSIC_settings,EDF_indices2load,HDR.label);

%consolidate the list of EDF indices that will be loaded by removing any
%initialized index locations that did not have unique channel names

if(isempty(EDF_indices2load))
    event_with_no_channels = false;
    for e=1:numel(localBATCH_PROCESS.event_settings)
       if(isempty(localBATCH_PROCESS.event_settings{e}.channel_labels));
           event_with_no_channels = true;
       end
    end
    for a=1:numel(localBATCH_PROCESS.artifact_settings)
       if(isempty(localBATCH_PROCESS.artifact_settings{a}.channel_labels));
           event_with_no_channels = true;
       end
    end
    

    if(~event_with_no_channels)
        ME = MException('VerifyPrimaryChannel','Primary Channel not found');
        throw(ME);
    else
        %dangerous if using a no channel detection method (e.g. screen
        %capture and a regular detection method.  Possible to have missed a
        %channel loading, but don't get it logged because the program
        %continues on here anyway since the non-channel detection method
        %exists
    end
end;

EDF_indices2load = cell2mat(EDF_indices2load);
all_indices = EDF_indices2load;  %keep track of all indices
loadable_indices = EDF_indices2load<=max_HDR_labels;
EDF_indices2load = EDF_indices2load(loadable_indices);
[HDR, signals] = ...
    loadEDF(fullfile(pathname,filename),EDF_indices2load);

studyInfo.startDateTime = HDR.T0;
studyInfo.study_duration_in_seconds = HDR.duration_sec;
studyInfo.study_duration_in_samples = HDR.duration_samples;
studyInfo.num_epochs = ceil(HDR.duration_sec/localBATCH_PROCESS.standard_epoch_sec);  %take all of the epochs, even the last one...

%The ability to synthesize new channels from loaded channels complicates
%matters.  Channel indices for the EDF are loaded and then referenced in the order they are loaded
%A mapping occurs going from EDF_index to channel_index.  EDF_index can be
%in any order, but channel_index increases from 1 to the number of channels
%selected, whether created or loaded.  To keep things compatible, I chose
%approach B which loads the loadable EDF indices (those which are in
%the EDF and not from synthesized channels), and then iterate through the
%list of all EDF_indices to create the source channel and apply the filter
%next.
localCHANNELS_CONTAINER = CLASS_channels_container;
localCHANNELS_CONTAINER.setDefaultSamplerate(localBATCH_PROCESS.base_samplerate);
localCHANNELS_CONTAINER.cell_of_channels = cell(numel(all_indices),1);
localCHANNELS_CONTAINER.num_channels = numel(all_indices);  %this must occur before synthesizing channels, otherwise it will 
    %error out because the src_index will be greater than the num_channels
    %(default is 0).
cur_channel = 1;
for k = 1:numel(all_indices)
    if(loadable_indices(k))
        EDF_index = all_indices(k);
        src_index = EDF_index;
        if(numel(EDF_index)==1)
            channel_data = signals{cur_channel};
            src_label = HDR.label{EDF_index};
            src_samplerate = HDR.samplerate(EDF_index);
            cur_channel = cur_channel+1;
        elseif(numel(EDF_index)==2)
            channel_data = signals{cur_channel}-signals{cur_channel+1};
            src_label = strcat(HDR.label{EDF_index(1)},'-',HDR.label{EDF_index(1)});
            src_samplerate = HDR.samplerate(EDF_index(1));
            HDR.samplerate(EDF_index(1));
            cur_channel=cur_channel+2;
        else
            ME = MException('Channel not found','An empty channel list was caught in load_file.m');
            throw(ME);
        end
%         CHANNELS_CONTAINER.addChannel(channel_data,src_label,src_index,src_samplerate);
        localCHANNELS_CONTAINER.replaceChannel(k,channel_data,src_label,src_index,src_samplerate);
    end
end

cur_synth_channel = 1;
%now go through and produce the channels meant to be synthesized
for k = 1:numel(all_indices)
    if(~loadable_indices(k))
        synth_settings = localBATCH_PROCESS.synth_CHANNEL.settings_lite{cur_synth_channel};
        filterStruct = localBATCH_PROCESS.synth_CHANNEL.structs{cur_synth_channel};
        synthLabel = localBATCH_PROCESS.synth_CHANNEL.names{cur_synth_channel};
        for j=1:numel(filterStruct);
            filterStruct(j).src_channel_index = synth_settings.channel_indices(find(strcmp(filterStruct(j).src_channel_label,synth_settings.channel_labels),1));
            for m=1:numel(filterStruct(j).ref_channel_index)
                filterStruct(j).ref_channel_index(m) = synth_settings.channel_indices(find(strcmp(filterStruct(j).ref_channel_label(m),synth_settings.channel_labels),1));
            end
        end    
        %synthesize new channel (src_container_channel_indices,
        %filterStructs, synth_titles,optional_dest_container_indices)
        localCHANNELS_CONTAINER.synthesize(synth_settings.channel_indices(1),filterStruct,synthLabel,k);
        cur_synth_channel = cur_synth_channel+1;
    end
end


function [detection_settings, EDF_indices2load] = getChannelIndices(detection_settings,EDF_indices2load,EDF_labels)
%finds matches in the cell string channel_labels2load within EDF_labels and
%upon finding a match it checks if the index has already been marked for
%loading in which case the corresponding channel_indices value is set to
%the previously marked value, otherwise if there is a string match in
%EDF_labels but no index match in channel_indices, then the number of edfs
%to load is increased by one, with the EDF_indices to load at that
%incremented index set to the correspodning EDF_label match, and the
%class_channel_index is set to the number of edfs to load.  
%
%detection_settings is a cell of structs with the following fields
%.channel_labels = 1 or 2 element cell of EDF label names for desired
%channel
%.method_label = character string of the label used for the detection
%method
%.batch_mode_score = value that will be assigned to detected instances of this
%event in batch mode, under artifact (A) column
%.method_function = matlab function that is called to detect the events


for r = 1:numel(detection_settings)
    num_channels = numel(detection_settings{r}.channel_labels);
    
    %make room in memory for the channel_indices reference
    detection_settings{r}.channel_indices = zeros(1,num_channels);
    for c=1:num_channels
        ind2load = find(strcmp(detection_settings{r}.channel_labels{c},EDF_labels)); %this is the index into EDF_labels, the .EDF
    
        %handle the cases when I do not have the right referencing available...
        if(isempty(ind2load))
            
            %handle the case where I need a referenced label,
            indexPair = findAlternativeChannels(detection_settings{r}.channel_labels{c},EDF_labels);

            if(isempty(indexPair))
                ME = MException('Batch:load_file',['Channel label (',detection_settings{r}.channel_labels{c},') not found in this EDF.']);
                throw(ME);
            else
                %handle the case of the indexPair existing
                ind2load = indexPair(1);
                
                %check if this index has already been marked for labeling
                loadedInd = [];
                for k=1:numel(EDF_indices2load)
                    if(ind2load == EDF_indices2load{k}(1))
                        loadedInd = k;
                        break;
                    end;
                end;

                if(isempty(loadedInd))
                    %update the vector of indices to load to contain the index that
                    %was found in the EDF header
                    EDF_indices2load{end+1} = ind2load;
                    detection_settings{r}.channel_indices(c) = numel(EDF_indices2load);
                else
                    detection_settings{r}.channel_indices(c) = loadedInd;
                end
            end            
        else            
            %check if this index has already been marked for labeling
            loadedInd = [];
            for k=1:numel(EDF_indices2load)
                if(ind2load == EDF_indices2load{k}(1))
                    loadedInd = k;
                    break;
                end;
            end;            
            %if it has not been marked for labeling, then mark it and adjust
            %load counts
            if(isempty(loadedInd))
                %update the vector of indices to load to contain the index that
                %was found in the EDF header
                EDF_indices2load{end+1} = ind2load;
                detection_settings{r}.channel_indices(c) = numel(EDF_indices2load);
                
            %otherwise, just update the class_channel_indices reference vector
            %to the previously assigned CHANNELS_CONTAINER index
            else
                detection_settings{r}.channel_indices(c) = loadedInd;
            end            
        end;
    end
end

function EDF_channel_index_pair = findAlternativeChannels(desired_channel_label,HDR_labels)
% %handle the case when we are running the batch mode and did not find
% %the index to load.  This will load the signal parts, subtract, and
% %create the desired signal if correct channel pairs are found
    EDF_channel_index_pair = [];
    alternative_names = [];
    if(strmatch(desired_channel_label,'C3-M2'))
        alternative_names = {{'C3','A2'},{'C3-Cz','M2-Cz'},{'C3-CmnRef','M2-CmnRef'}};
    elseif(strmatch(desired_channel_label,'O1-M2'))
        alternative_names = {{'O1','A2'},{'O1-Cz','M2-Cz'},{'O1-CmnRef','M2-CmnRef'}};
    end
    for k=1:numel(alternative_names)
        ind1 = strmatch(alternative_names{k}{1},HDR_labels,'exact');
        ind2 = strmatch(alternative_names{k}{2},HDR_labels,'exact');
        if(~isempty(ind1)&&~isempty(ind2))
            
            EDF_channel_index_pair = [ind1, ind2]; %update for class channel construction (following)
            %                 cellOfevents_class = cell(size(indices2load));
            break;
        end
    end

%verify_synthetic_channel_usage 
% %FIXED (BUG) - not referencing a synthesized channel in an event or artifact
% %detector, or in a psd analysis, may cause problems.  Need to remove any
% %unreferenced synthetic channels first before continuing with this
% %analysis.  Otherwise, the wrong synthetic channel may get put in at the
% %stored location of the correct synthetic channel
function BATCH_PROCESS = verify_synthetic_channel_usage(BATCH_PROCESS)  

if(numel(BATCH_PROCESS.synth_CHANNEL.structs)>=1)
    verified_indices = false(numel(BATCH_PROCESS.synth_CHANNEL.structs),1);
    all_labels = {};
    for j=1:numel(BATCH_PROCESS.artifact_settings)
        all_labels = [all_labels;BATCH_PROCESS.artifact_settings{j}.channel_labels];
    end
    for j=1:numel(BATCH_PROCESS.event_settings)
        all_labels = [all_labels;BATCH_PROCESS.event_settings{j}.channel_labels];
    end
    for j=1:numel(BATCH_PROCESS.PSD_settings)
        all_labels = [all_labels;BATCH_PROCESS.PSD_settings{j}.channel_labels];
    end
    for j=1:numel(BATCH_PROCESS.MUSIC_settings)
        all_labels = [all_labels;BATCH_PROCESS.MUSIC_settings{j}.channel_labels];
    end
   
    for k = 1:numel(verified_indices)
        %check each name and see if there is a match 
        if(any(strcmp(BATCH_PROCESS.synth_CHANNEL.names{k},all_labels)))
           verified_indices(k) = true; 
        end
    end
    BATCH_PROCESS.synth_CHANNEL.names(~verified_indices) = [];
    BATCH_PROCESS.synth_CHANNEL.structs(~verified_indices) = [];
    BATCH_PROCESS.synth_CHANNEL.settings_lite(~verified_indices) = [];
end
