function save_artifacts()
% save_artifacts()

% Hyatt Moore IV (early 2010)
% An initial artifact detection methods which I retain here as legacy code
% and a reminder of where I started.

global CLASS_channel_containerCell;
global CHANNEL_INDICES;
global WORKSPACE;
global STATE;
global BATCH_PROCESS;
global DEFAULTS;
global ARTIFACT_DLG;

filename_out = WORKSPACE.cur_filename;
if(STATE.batch_process_running)
    filename_out = [filename_out(1:end-3) BATCH_PROCESS.output_files.artifacts_filename];
else
    filename_out = [filename_out(1:end-3) 'art.txt'];
end;

% filename_out(end-3:end) = '.txt';
fout = fopen(fullfile(WORKSPACE.cur_pathname,DEFAULTS.output_pathname,filename_out),'w');
fprintf(fout,'EEG Long RMS Threshold (min):\t %.2f\r\n',ARTIFACT_DLG.eeg.rms_long_min);
fprintf(fout,'EEG Short RMS Threshold (sec):\t %.2f\r\n',ARTIFACT_DLG.eeg.rms_short_sec);
fprintf(fout,'EEG Threshold Scale Factor:\t %.2f\r\n',ARTIFACT_DLG.eeg.scale_factor);
fprintf(fout,'EMG Long RMS Threshold (min):\t %.2f\r\n',ARTIFACT_DLG.emg.rms_long_min);
fprintf(fout,'EMG Short RMS Threshold (sec):\t %.2f\r\n',ARTIFACT_DLG.emg.rms_short_sec);
fprintf(fout,'EMG Threshold Scale Factor:\t %.2f\r\n',ARTIFACT_DLG.emg.scale_factor);

fprintf(fout,'SEQUENCE\tNUMBER\tSTART\tDURATION\tTYPE\tCHANNEL\r\n');
% fprintf(fout,'SEQUENCE\tNUMBER\tSTART\tDURATION\tTYPE\tCHANNEL\tFirst
% Pct\tFinal Pct\r\n');

PRIMARY =  CLASS_channel_containerCell{CHANNEL_INDICES.PRIMARY};
artifact_of_interest_index = 1; %clean this up later to allow more abstraction PRIMARY.findEvent('hello');
crossings = PRIMARY.event_object_cell{artifact_of_interest_index}.start_stop_matrix;
r = size(crossings,1);
num_artifacts = 0;
CHANNEL = [num2str(PRIMARY.EDF_index),'--1'];
if(~STATE.batch_process_running)
    h = waitbar(0,'saving file');
end;
for k=1:r
    duration = (crossings(k,2)-crossings(k,1))/DEFAULTS.fs;
    start = DEFAULTS.t0;
    start(6) = start(6)+crossings(k,1)/DEFAULTS.fs; %add the seconds here
    start = datenum(start);
    day = 1;
    if(str2double(datestr(start,'dd'))~=DEFAULTS.t0(3)) %are the days the same or did we go past midnight?
        day = 2; %went on to the second day
    end;
    start = datestr(start,'HH:MM:SS.FFF');
    type = '20Hz_HP_threshold_filter';
    sequence = 1;
    num_artifacts = num_artifacts+1;

    fprintf(fout,'%i\t%i\t%02i %s\t%.3f\t%s\t%s\r\n',sequence, num_artifacts, day, start, duration, type, CHANNEL);

%     fprintf(fout,'%i\t%i\t%02i %s\t%.3f\t%s\t%s\t%.2f\t%.2f\r\n',sequence, num_artifacts, day, start, duration, type, CHANNEL,...
%         handles.user.final_art_density_line_with_no_threshold_scales_accounted_for(crossings(k,1))*100,...
%         handles.user.final_art_density_line(crossings(k,1))*100);

    if(~STATE.batch_process_running)
        
        if(mod(k,101)==0 && h)
            waitbar(k/r,h);
        end;
    end;
end;

fclose(fout);

disp([num2str(num_artifacts) ' artifacts saved to file: ' filename_out]);
if(~STATE.batch_process_running)
    delete(h);
end;
