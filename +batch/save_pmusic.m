function save_pmusic(channel_ref,filename_out,optional_MUSIC_settings)
% save_pmusic(channel_ref,filename_out,optional_MUSIC_settings)
%
%
% saves pmusic spectrum as calculated using MATLABS pmusic function 
% called from within SEV's batch mode.
%
% Hyatt Moore IV (likely 2011-2012)
global CHANNELS_CONTAINER;
global MARKING;
global BATCH_PROCESS;
global ARTIFACT_CONTAINER;


channel_index = 0; %this cause it to crash if nothing is found
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
    
    CHANNEL = CHANNELS_CONTAINER.cell_of_channels{channel_index};
    
    if(isempty(CHANNEL.MUSIC))
        if(nargin==2)
            CHANNEL.calculate_PMUSIC();
        else
            CHANNEL.calculate_PMUSIC([],optional_MUSIC_settings);
        end
    end;
    
    MUSIC = CHANNEL.MUSIC;
    y = MUSIC.magnitudes;
    rows = size(y,1);
    
    study_duration_in_seconds = numel(CHANNEL.raw_data)/CHANNEL.sample_rate;
    E = floor(0:MUSIC.interval_sec/BATCH_PROCESS.standard_epoch_sec:(study_duration_in_seconds-MUSIC.window_length_sec)/BATCH_PROCESS.standard_epoch_sec)'+1;
    S = MARKING.sev_STAGES.line(E);

    no_artifact_label = '''';
    A_ind = false(numel(E),ARTIFACT_CONTAINER.num_events);
    ArtifactLabels=repmat(' ',size(A_ind)); %initialize to blanks
    for k = 1:ARTIFACT_CONTAINER.num_events
        artifact_indices = ARTIFACT_CONTAINER.cell_of_events{k}.start_stop_matrix;
        
        artifacts_per_periodogram_epoch = sample2epoch(artifact_indices,MUSIC.interval_sec,CHANNEL.sample_rate);
                
        %need to handle the overlapping case differently here...
        if(MUSIC.window_length_sec~=MUSIC.interval_sec)
            %window_sec must be greater than interval_sec if they are not
            %equal - this is ensured in the MUSIC settings GUI - though
            %adjusting the parametes externally may cause trouble!
            overlap_sec = ceil(MUSIC.window_length_sec-MUSIC.interval_sec);
            artifacts_per_periodogram_epoch(2:end,1) = artifacts_per_periodogram_epoch(2:end,1)-overlap_sec;
        end;

        %assign the corresponding column of A to the artifacts indices
        %found in the current artifact method
        for r = 1:size(artifacts_per_periodogram_epoch,1)
            A_ind(artifacts_per_periodogram_epoch(r,1):artifacts_per_periodogram_epoch(r,2),k)=true; %ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_score;
        end;
        ArtifactLabels(A_ind(:,k),k) = ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_label;
    end
    A_ind = sum(A_ind,2);
    
    %just make the first row be this character
    ArtifactLabels(~A_ind,1) = no_artifact_label;  %refer to no artifacts...
    
    %and a quick second pass, I hope...

    %final artifact is a sum of the different artifact methods that were used.  The different components that contribute to a non-zero artifact score can be discriminated using knowledge of the artifacts batch_mode_score
%     A = sum(A,2);
    
%     if(isfield(BATCH_PROCESS,'output_path'))
%         if(isfield(BATCH_PROCESS,'PMUSIC_path'))
%             fout = fopen(fullfile(BATCH_PROCESS.output_path,BATCH_PROCESS.PMUSIC_path,filename_out),'w');
%         else
%             fout = fopen(fullfile(BATCH_PROCESS.output_path,filename_out),'w');
%         end
%     else
%         disp('BATCH_PROCESS.output_path not set - saving to current directory!');
%         fout = fopen(fullfile(pwd,filename_out),'w');
%     end
    fout = fopen(filename_out,'w');

    analysis_CHANNEL_label = CHANNEL.EDF_label;
    fprintf(fout,['#Power Spectral Density values from FFTs with the following parameters: (Batch ID: %s)\r\n'...
        ,'#\tCHANNEL:\t%s\r\n'...
        ,'#\twindow length (seconds):\t%0.1f\r\n'...
        ,'#\tFFT length (samples):\t%i\r\n'...
        ,'#\tFFT interval (taken every _ seconds):\t%0.1f\r\n'...
        ,'#\tInitial Sample Rate(Hz):\t%i\r\n'...
        ,'#\tFinal Sample Rate(Hz):\t%i\r\n'...
        ,'%s\tSlow\tDelta\tTheta\tAlpha\tSigma\tBeta\tGamma\tMean0_30\tSum0_30\tA\tS\tE\r\n'],BATCH_PROCESS.start_time,analysis_CHANNEL_label,MUSIC.window_length_sec,MUSIC.nfft,MUSIC.interval_sec...
        ,CHANNEL.initial_sample_rate,CHANNEL.sample_rate...
        ,num2str(MUSIC.freq_vec,'\t%0.001f'));%'\t%0.1f'
%     fclose(fout);
    
    %MUSIC.freq_vec is a row vector, delivered by calcPMUSIC
    freqs = MUSIC.freq_vec;
    slow = mean(y(:,freqs>0&freqs<4),2); %mean across the rows to produce a column vector
    
    delta = sum(y(:,freqs>=0.5&freqs<4),2); %mean across the rows to produce a column vector
    theta = sum(y(:,freqs>=4&freqs<8),2);
    alpha = sum(y(:,freqs>=8&freqs<12),2);
    sigma = sum(y(:,freqs>=12&freqs<16),2);
    beta  = sum(y(:,freqs>=16&freqs<30),2);
    gamma = sum(y(:,freqs>=30),2);
    
    mean0_30  = mean(y(:,freqs>0&freqs<=30),2);
    sum0_30  = sum(y(:,freqs>0&freqs<=30),2);

    y = [y, slow, delta, theta, alpha, sigma, beta, gamma, mean0_30, sum0_30];
    
    numeric_output_str = [repmat('%0.4f\t',1,size(y,2)),repmat('%c',1,size(ArtifactLabels,2)),'\t%u\t%u\n'];
    
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
    x = sprintf('%i %0.04f-second psuedo-MUSIC spectrums saved to %s\n',rows,MUSIC.window_length_sec,filename_out);

    disp(x);
    
catch ME
%     warnmsg = ME.message;
%     stack_error = ME.stack(1);
%     warnmsg = sprintf('%s\r\n\tFILE: %s\f<a href="matlab:opentoline(''%s'',%s)">LINE: %s</a>\fFUNCTION: %s', warnmsg,stack_error.file,stack_error.file,num2str(stack_error.line),num2str(stack_error.line), stack_error.name);
%     disp(warnmsg);
     rethrow(ME);
end;
