function save_periodograms_lite(channel_ref,filename_out,optional_PSD_settings)
% hObject    handle to menu_file_save_psd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Written by Hyatt Moore IV 
% (date created is likely 2010-2011)
% lite version added July, 29, 2013
global CHANNELS_CONTAINER;
global MARKING;
global BATCH_PROCESS;
global ARTIFACT_CONTAINER;
global STATE;

channel_index = 0; %this causes crash if nothing is found
if(isnumeric(channel_ref))
    channel_index = channel_ref;
elseif(ischar(channel_ref))
    for k=1:CHANNELS_CONTAINER.num_channels
        if(strcmp(CHANNELS_CONTAINER.cell_of_channels{k}.EDF_label,channel_ref))
            channel_index = k;
            break;
        end;
    end;
end;

try
    PRIMARY = CHANNELS_CONTAINER.cell_of_channels{channel_index};
    
    if(isempty(PRIMARY.PSD))
        if(nargin==2)
            PRIMARY.calculate_PSD();
        else
            PRIMARY.calculate_PSD([],optional_PSD_settings);
        end
    end;
    
    PSD = PRIMARY.PSD;
    y = PSD.magnitude;
    rows = size(y,1);
    
    study_duration_in_seconds = numel(PRIMARY.raw_data)/PRIMARY.samplerate;
    E = floor(0:PSD.interval/BATCH_PROCESS.standard_epoch_sec:(study_duration_in_seconds-PSD.FFT_window_sec)/BATCH_PROCESS.standard_epoch_sec)'+1;
    S = MARKING.sev_STAGES.line(E);

%     no_artifact_label = '-';
    A_ind = false(numel(E),ARTIFACT_CONTAINER.num_events);
    ArtifactLabels=repmat('_',size(A_ind)); %initialize to blanks
%     ArtifactBool = zeros(numel(E),1);
    for k = 1:ARTIFACT_CONTAINER.num_events
        artifact_indices = ARTIFACT_CONTAINER.cell_of_events{k}.start_stop_matrix;
        
        %periodogram_epoch refers to an epoch that is measured in terms of
        %the periodogram length and not a 30-second length
        artifacts_per_periodogram_epoch = sample2epoch(artifact_indices,PSD.interval,PRIMARY.samplerate);
                
        %need to handle the overlapping case differently here...
        if(PSD.FFT_window_sec~=PSD.interval)
            %window_sec must be greater than interval_sec if they are not
            %equal - this is ensured in the PSD settings GUI - though
            %adjusting the parametes externally may cause trouble!
            overlap_sec = ceil(PSD.FFT_window_sec-PSD.interval);
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

     if(STATE.batch_process_running)
         samples_per_artifact = PSD.interval*PRIMARY.samplerate;
         artifact_mat = find(ArtifactBool);
         artifact_mat = [(artifact_mat-1)*samples_per_artifact+1,artifact_mat*samples_per_artifact];
         if(BATCH_PROCESS.output_files.cumulative_stats_flag)
             batch.updateBatchStatisticsTally(PRIMARY.samplerate,artifact_mat);
         end
         if(BATCH_PROCESS.output_files.individual_stats_flag) %artifact statistics
             batch.saveArtifactandStageStatistics(PRIMARY.samplerate,artifact_mat);
         end
     end
    fout = fopen(filename_out,'w');

    analysis_CHANNEL_label = PRIMARY.EDF_label;
    fprintf(fout,['#Power Spectral Density values from FFTs with the following parameters: (Batch ID: %s)\r\n'...
        ,'#\tCHANNEL:\t%s\r\n'...
        ,'#\twindow length (seconds):\t%0.1f\r\n'...
        ,'#\tFFT length (samples):\t%i\r\n'...
        ,'#\tFFT interval (taken every _ seconds):\t%0.1f\r\n'...
        ,'#\tInitial Sample Rate(Hz):\t%i\r\n'...
        ,'#\tFinal Sample Rate(Hz):\t%i\r\n'...
        ,'Delta\tTheta\tAlpha\tSigma\tBeta\tGamma\tMean0_30\tSum0_30\tA\tA_type\tS\tE\r\n'],BATCH_PROCESS.start_time,analysis_CHANNEL_label,PSD.FFT_window_sec,PSD.nfft,PSD.interval...
        ,PRIMARY.src_samplerate,PRIMARY.samplerate);
    
    %psd.x is a row vector, delivered by calcPSD
    freqs = PSD.x;
    
    delta = sum(y(:,freqs>=0.5&freqs<4),2); %mean across the rows to produce a column vector
    theta = sum(y(:,freqs>=4&freqs<8),2);
    alpha = sum(y(:,freqs>=8&freqs<12),2);
    sigma = sum(y(:,freqs>=12&freqs<16),2);
    beta  = sum(y(:,freqs>=16&freqs<30),2);
    gamma = sum(y(:,freqs>=30),2);
    
    mean0_30  = mean(y(:,freqs>0&freqs<=30),2);
    sum0_30  = sum(y(:,freqs>0&freqs<=30),2);

    y = [delta, theta, alpha, sigma, beta, gamma, mean0_30, sum0_30, ArtifactBool];
    
    numeric_output_str = [repmat('%0.4f\t',1,size(y,2)),repmat('%c',1,size(ArtifactLabels,2)),'\t%u\t%u\r\n'];
    
    yall = [y,ArtifactLabels+0,S,E];
    
    fprintf(fout,numeric_output_str,yall');

%     tic
%     for row = 1:r
%         fprintf(fout,numeric_output_str,y(row,:),ArtifactLabels(row,:),S(row),E(row));
%     end;
%     toc
    
    fclose(fout);
%     tic
%     save(fullfile(BATCH_PROCESS.output_path,filename_out),'y','-tabs','-ASCII','-append');
%     toc
    x = sprintf('%i %0.04f-second periodograms saved to %s\n',rows,PSD.FFT_window_sec,filename_out);

    disp(x);
    
catch ME
%     warnmsg = ME.message;
%     stack_error = ME.stack(1);
%     warnmsg = sprintf('%s\r\n\tFILE: %s\f<a href="matlab:opentoline(''%s'',%s)">LINE: %s</a>\fFUNCTION: %s', warnmsg,stack_error.file,stack_error.file,num2str(stack_error.line),num2str(stack_error.line), stack_error.name);
%     disp(warnmsg);
     rethrow(ME);
end;
