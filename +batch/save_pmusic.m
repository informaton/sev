%> @brief Calculates and saves MUSIC spectrum to text file as calculated on the input
%> channel data according to the settings provided,
%> @param channelObj Instance of CLASS_channel
%> @param StagingStruct Sleep staging struct (e.g. hypnogram data)
%> @param PSD_settings Struct with field/values which describe how to
%> calculate MUSIC
%> @param filename_out Name of the text file to store periodograms to
%> @param ARTIFACT_CONTAINER Instance of CLASS_events_container which is
%> used to identify overlap between periodograms and events/artifacts.
function save_pmusic(channelObj,StagingStruct,PMUSIC_settings,filename_out,ARTIFACT_CONTAINER,batchID)

% saves pmusic spectrum as calculated using MATLABS pmusic function 
% called from within SEV's batch mode.
%
% Hyatt Moore IV (likely 2011-2012)
% Updated 11/12/13

try
    
    if(isempty(PMUSIC_settings))
        channelObj.calculate_PMUSIC();
    else
        channelObj.calculate_PMUSIC(PMUSIC_settings);
    end
    

    y = channelObj.MUSIC.magnitudes;
    rows = size(y,1);
    
    study_duration_in_seconds = numel(channelObj.raw_data)/channelObj.samplerate;
    E = floor(0:channelObj.MUSIC.interval_sec/StagingStruct.standard_epoch_sec:(study_duration_in_seconds-channelObj.MUSIC.window_length_sec)/StagingStruct.standard_epoch_sec)'+1;
    S = StagingStruct.line(E);

%     no_artifact_label = '-';
    A_ind = false(numel(E),ARTIFACT_CONTAINER.num_events);
    ArtifactLabels=repmat('_',size(A_ind)); %initialize to blanks
%     ArtifactBool = zeros(numel(E),1);
    for k = 1:ARTIFACT_CONTAINER.num_events
        artifact_indices = ARTIFACT_CONTAINER.cell_of_events{k}.start_stop_matrix;
        
        %periodogram_epoch refers to an epoch that is measured in terms of
        %the periodogram length and not a 30-second length
        artifacts_per_periodogram_epoch = sample2epoch(artifact_indices,channelObj.MUSIC.interval_sec,channelObj.samplerate);
                
        %need to handle the overlapping case differently here...
        if(channelObj.MUSIC.window_length_sec~=channelObj.MUSIC.interval_sec)
            %window_sec must be greater than interval_sec if they are not
            %equal - this is ensured in the PSD settings GUI - though
            %adjusting the parametes externally may cause trouble!
            overlap_sec = ceil(channelObj.MUSIC.window_length_sec-channelObj.MUSIC.interval_sec);
            artifacts_per_periodogram_epoch(2:end,1) = artifacts_per_periodogram_epoch(2:end,1)-overlap_sec;
        end;

        %assign the corresponding column of A to the artifacts indices
        %found in the current artifact method
        for r = 1:size(artifacts_per_periodogram_epoch,1)
            A_ind(artifacts_per_periodogram_epoch(r,1):artifacts_per_periodogram_epoch(r,2),k)=true; %ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_score;
        end;
        ArtifactLabels(A_ind(:,k),k) = ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_label(1);
%         ArtifactBool(A_ind(:,k)) = 1;
    end
    
     ArtifactBool = sum(A_ind,2)>0;

%      samples_per_artifact = channelObj.MUSIC.interval_sec*channelObj.samplerate;
%      artifact_mat = find(ArtifactBool);
%      artifact_mat = [(artifact_mat-1)*samples_per_artifact+1,artifact_mat*samples_per_artifact];
     
%      if(BATCH_PROCESS.output_files.cumulative_stats_flag)
%          batch.updateBatchStatisticsTally(channelObj.samplerate,artifact_mat);
%      end
%      if(BATCH_PROCESS.output_files.individual_stats_flag) %artifact statistics
%          batch.saveArtifactandStageStatistics(channelObj.samplerate,artifact_mat);
%      end

    fout = fopen(filename_out,'w');

    analysis_CHANNEL_label = channelObj.EDF_label;
    fprintf(fout,['#Power Spectral Density values from MUSIC with the following parameters: (Batch ID: %s)\r\n'...
        ,'#\tCHANNEL:\t%s\r\n'...
        ,'#\tWindow length (seconds):\t%0.1f\r\n'...
        ,'#\tWindow length (samples):\t%i\r\n'...
        ,'#\tWindow interval (taken every _ seconds):\t%0.1f\r\n'...
        ,'#\tInitial Sample Rate(Hz):\t%i\r\n'...
        ,'#\tFinal Sample Rate(Hz):\t%i\r\n'...
        ,'%s\tSlow\tDelta\tTheta\tAlpha\tSigma\tBeta\tGamma\tMean0_30\tSum0_30\tA\tA_type\tS\tE\r\n'],batchID,analysis_CHANNEL_label,channelObj.MUSIC.window_length_sec,numel(channelObj.MUSIC.freq_vec),channelObj.MUSIC.interval_sec...
        ,channelObj.src_samplerate,channelObj.samplerate...
        ,num2str(channelObj.MUSIC.freq_vec,'\t%0.001f'));%'\t%0.1f'
    
    %psd.x is a row vector, delivered by calcPSD
    freqs = channelObj.MUSIC.freq_vec;
    slow = mean(y(:,freqs>0&freqs<4),2); %mean across the rows to produce a column vector
    
    delta = sum(y(:,freqs>=0.5&freqs<4),2); %mean across the rows to produce a column vector
    theta = sum(y(:,freqs>=4&freqs<8),2);
    alpha = sum(y(:,freqs>=8&freqs<12),2);
    sigma = sum(y(:,freqs>=12&freqs<16),2);
    beta  = sum(y(:,freqs>=16&freqs<30),2);
    gamma = sum(y(:,freqs>=30),2);
    
    mean0_30  = mean(y(:,freqs>0&freqs<=30),2);
    sum0_30  = sum(y(:,freqs>0&freqs<=30),2);

    y = [y, slow, delta, theta, alpha, sigma, beta, gamma, mean0_30, sum0_30, ArtifactBool];
    
    numeric_output_str = [repmat('%0.4f\t',1,size(y,2)),repmat('%c',1,size(ArtifactLabels,2)),'\t%u\t%u\r\n'];
    
    yall = [y,ArtifactLabels+0,S,E];
    
    fprintf(fout,numeric_output_str,yall');

    
    fclose(fout);
    
    fprintf('%i %0.04f-second psuedo-MUSIC spectrums saved to %s\n',rows,channelObj.MUSIC.window_length_sec,filename_out);
    
    
catch ME
    showME(ME);
    rethrow(ME);
end;


