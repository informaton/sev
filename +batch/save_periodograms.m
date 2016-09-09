%> @brief Calculates periodogram of input channel data according to the
%> PSD settings provided and saves output to a text file.
%> @param channelObj Instance of CLASS_channel
%> @param StagingStruct Sleep staging struct (e.g. hypnogram data)
%> @param PSD_settings Struct with field/values which describe how to
%> calculate periodograms
%> @param filename_out Name of the text file to store periodograms to
%> @param ARTIFACT_CONTAINER Instance of CLASS_events_container which is
%> used to identify overlap between periodograms and events/artifacts.
function save_periodograms(channelObj,StagingStruct,PSD_settings,filename_out,ARTIFACT_CONTAINER,batchID)

%Written by Hyatt Moore IV 
% (date created is likely 2010-2011)
% Updated 11/12/13

% Updated 8/5/2016 To account for modifiction to calcPSD: now returns U_psd
% and U_power which is helpful in the case of 'none' estimate.
% - Also increase number of digits presented in the frequency header line
try
    
    if(isempty(PSD_settings))
        channelObj.calculate_PSD();
    else
        channelObj.calculate_PSD(PSD_settings);
    end
    

    y = channelObj.PSD.magnitude;
    rows = size(y,1);
    
    study_duration_in_seconds = numel(channelObj.raw_data)/channelObj.samplerate;
    E = floor(0:channelObj.PSD.interval/StagingStruct.standard_epoch_sec:(study_duration_in_seconds-channelObj.PSD.FFT_window_sec)/StagingStruct.standard_epoch_sec)'+1;
    S = StagingStruct.line(E);

    numPeriodograms = numel(E);
%     no_artifact_label = '-';
    A_ind = false(numPeriodograms,ARTIFACT_CONTAINER.num_events);
    ArtifactLabels=repmat('_',size(A_ind)); %initialize to blanks
%     ArtifactBool = zeros(numel(E),1);
    for k = 1:ARTIFACT_CONTAINER.num_events
        artifact_indices = ARTIFACT_CONTAINER.cell_of_events{k}.start_stop_matrix;
        
        %periodogram_epoch refers to an epoch that is measured in terms of
        %the periodogram length and not a 30-second length
        artifacts_per_periodogram_epoch = sample2epoch(artifact_indices,channelObj.PSD.interval,channelObj.samplerate);
        
        artifacts_per_periodogram_epoch = min(artifacts_per_periodogram_epoch,numPeriodograms);
        
        
        % 8/30/2016 Dropped this aspect as I can no longer see how it is
        % useful to shring the periodogram window here.
        % Begin section to drop:  

        %need to handle the overlapping case differently here...
        %         if(channelObj.PSD.FFT_window_sec~=channelObj.PSD.interval)
        %             %window_sec must be greater than interval_sec if they are not
        %             %equal - this is ensured in the PSD settings GUI - though
        %             %adjusting the parametes externally may cause trouble!
        %             overlap_sec = ceil(channelObj.PSD.FFT_window_sec-channelObj.PSD.interval);
        %             artifacts_per_periodogram_epoch(2:end,1) = artifacts_per_periodogram_epoch(2:end,1)-overlap_sec;
        %
        %             % Avoid going too early
        %             artifacts_per_periodogram_epoch = max(artifacts_per_periodogram_epoch,1);
        %
        %         end;
        
        % 8/30/2016 End of section to drop.
        
        
        

        %assign the corresponding column of A to the artifacts indices
        %found in the current artifact method
        for r = 1:size(artifacts_per_periodogram_epoch,1)
            A_ind(artifacts_per_periodogram_epoch(r,1):artifacts_per_periodogram_epoch(r,2),k)=true; %ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_score;
        end;
        
        % Occassionally a detector will get over zealous and mark artifact
        % outside the actual data range!  Need to reign it back in here.
        if(size(A_ind,1)>numel(E))
            A_ind = A_ind(1:numel(E),:); 
        end
        
        ArtifactLabels(A_ind(:,k),k) = ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_label(1);
%         ArtifactBool(A_ind(:,k)) = 1;
    end
    
     ArtifactBool = sum(A_ind,2)>0;

%      samples_per_artifact = channelObj.PSD.interval*channelObj.samplerate;
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
    fprintf(fout,['#Power Spectral Density values from FFTs with the following parameters: (Batch ID: %s)\r\n'...
        ,'#\tCHANNEL:\t%s\r\n'...
        ,'#\twindow length (seconds):\t%0.1f\r\n'...
        ,'#\tFFT length (samples):\t%i\r\n'...
        ,'#\tFFT interval (taken every _ seconds):\t%0.1f\r\n'...
        ,'#\tInitial Sample Rate(Hz):\t%i\r\n'...
        ,'#\tFinal Sample Rate(Hz):\t%i\r\n'...
        ,'#\tSpectrum Type:\t%s\r\n'...
        ,'#\tU_psd:\t%f\r\n'...
        ,'#\tU_power:\t%f\r\n'...
        ,'%s\tSlow\tDelta\tTheta\tAlpha\tSigma\tBeta\tGamma\tMean0_30\tSum0_30\tA\tA_type\tS\tE\r\n'],batchID,analysis_CHANNEL_label,channelObj.PSD.FFT_window_sec,channelObj.PSD.nfft,channelObj.PSD.interval...
        , channelObj.src_samplerate, channelObj.samplerate...
        , channelObj.PSD.spectrum_type, channelObj.PSD.U_psd, channelObj.PSD.U_power...    
        , num2str(channelObj.PSD.x,'\t%0.4f'));%'\t%0.1f'
    
    %psd.x is a row vector, delivered by calcPSD
    freqs = channelObj.PSD.x;
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
    
    fprintf('%i %0.04f-second periodograms saved to %s\n',rows,channelObj.PSD.FFT_window_sec,filename_out);
    
    
catch ME
    showME(ME);
    rethrow(ME);
end;
