%> @file
%> @brief 
%======================================================================
%> @brief 
%> @param signalsCell Nx1 cell of signal data (each cell has a vector of time
%> series data)
%> @param Unused
%> @li @c 
%> @param stageStruct Struct with the following fields
%> @param fileInfoStruct Struct with the following fields
%> - @c edf_header - Struct containing header information for the edf
%> - @c eventsFullFilename - Full name of a SEV combatible event file
%> associated with the data.
%> @retval exportStruct Struct with the following fields on success (empty
%> otherwise)
%> - @c edf_filename
%> - @c channel_names
%> - @c channel_samplerates
%> - @c eyesclosed Struct with the following fields
%> -- @c channels Cell of channels 
%> -- @c sleep_stages vector of sleep stages scored in 30 second epochs
%> - @c nonwake Struct with the following fields
%> -- @c channels Cell of channels 
%> -- @c sleep_stages vector of sleep stages scored in 30 second epochs
%> @note: Written by Hyatt Moore IV, 5/11/2015, Stanford, CA
function exportStruct = export_candidate_eyesclosed(signalCell, params, stageStruct, fileInfoStruct)

% initialize default parameters
defaultParams.seconds_before_event = 1*60;
defaultParams.seconds_after_event = 2*60;
defaultParams.event_category = 'biocals';
defaultParams.event_description ='Eyes closed awake';
defaultParams.seconds_before_firstnonwake = 6*60;
defaultParams.seconds_after_firstnonwake = 1*60;


% return default parameters if no input arguments are provided.
if(nargin==0)
    exportStruct = defaultParams;
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
    
    secondsPerEpoch = stageStruct.standard_epoch_sec;

    samplerates = fileInfoStruct.edf_header.samplerate;
    exportStruct.edf_filename = fileInfoStruct.edf_name;
    exportStruct.channel_names = fileInfoStruct.edf_header.label;
    exportStruct.channel_samplerates = fileInfoStruct.edf_header.samplerate;
    
    SSC_evts = CLASS_codec.parseSSCevtsFile(fileInfoStruct.events_filename);
    event_index = find(strcmpi(SSC_evts.category,defaultParams.event_category)&strcmpi(SSC_evts.description,defaultParams.event_description),1);
    
    try
        if(~isempty(event_index))
            eventStartSample = SSC_evts.startStopSamples(event_index,1);
            eventRangeStartSample = eventStartSample - params.seconds_before_event*SSC_evts.samplerate;
            eventRangeStopSample = eventStartSample + params.seconds_after_event*SSC_evts.samplerate-1;
            
            eventRangeStartEpoch =  sample2epoch(eventRangeStartSample, secondsPerEpoch, SSC_evts.samplerate);
            eventRangeStopEpoch =  sample2epoch(eventRangeStopSample, secondsPerEpoch, SSC_evts.samplerate);
            
            eventEpochsOfInterest = eventRangeStartEpoch:eventRangeStopEpoch;
            eyesclosedStruct.sleep_stages = stageStruct.line(eventEpochsOfInterest);
            
            eyesclosedStruct.channels = [];
            channels = cell(size(signalCell));
            for s=1:numel(signalCell)
                samplerateConversion = samplerates(s)/SSC_evts.samplerate;
                firstSampleOfInterest = max(floor(eventRangeStartSample*samplerateConversion),1);
                lastSampleOfInterest = ceil(eventRangeStopSample*samplerateConversion);
                samplesOfInterest = firstSampleOfInterest:lastSampleOfInterest;
                channels{s} = single(signalCell{s}(samplesOfInterest));
                
            end
            eyesclosedStruct.channels = channels;
            
        else
            eyesclosedStruct = [];
        end
    catch me
        showME(me);
        eyesclosedStruct = [];
    end
    exportStruct.eyesclosed = eyesclosedStruct;
    
    
    if(~isempty(stageStruct.firstNonWake))
        try
            epochsBefore = params.seconds_before_firstnonwake/secondsPerEpoch;
            epochsAfter = params.seconds_after_firstnonwake/secondsPerEpoch-1;
            
            firstNonWakeEpochsOfInterest = (-epochsBefore:epochsAfter)+stageStruct.firstNonWake;
            firstNonWakeStagesOfInterest = stageStruct.line(firstNonWakeEpochsOfInterest);
            nonwakeStruct.channels = [];
            nonwakeStruct.sleep_stages = firstNonWakeStagesOfInterest;
            channels = cell(size(signalCell));
            
            
            for s=1:numel(signalCell)
                fs = samplerates(s);
                firstSampleOfInterest = (firstNonWakeEpochsOfInterest(1)-1)*secondsPerEpoch*fs+1;
                lastSampleOfInterest = (firstNonWakeEpochsOfInterest(end))*secondsPerEpoch*fs;
                samplesOfInterest = firstSampleOfInterest:lastSampleOfInterest;
                channels{s} = single(signalCell{s}(samplesOfInterest));
                
            end
            nonwakeStruct.channels = channels;
        catch me
            showME(me);
            nonwakeStruct = [];
        end
    else
        nonwakeStruct = [];
    end
    
    exportStruct.nonwake = nonwakeStruct;
    
    % return empty if nothing was found.
    if(isempty(exportStruct.nonwake)&&isempty(exportStruct.eyesclosed))
        exportStruct = [];
    end
end
end