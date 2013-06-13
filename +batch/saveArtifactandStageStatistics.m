function saveArtifactandStageStatistics(sample_rate,artifact_start_stops)
% saveArtifactandStageStatistics(sample_rate,artifact_start_stops)
%channel_obj is a channel_class object
%artifact_start_stops is a 2-column matrix of start and stop sample points
%of artifact occuring

%Hyatt Moore, IV (< June, 2013)
global BATCH_PROCESS;
global STATE;
global MARKING;

if(STATE.batch_process_running)
    filename_out = BATCH_PROCESS.cur_filename;

    filename_out = [filename_out(1:end-4) BATCH_PROCESS.output_files.individual_stats_filename_suffix];
    fout = fopen(fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.artifacts,filename_out),'w');

else
    filename_out = MARKING.sev_src_filename;

    filename_out = [filename_out(1:end-3) 'stats.txt'];
    fout = fopen(fullfile(MARKING.sev_src_pathname,filename_out),'w');

end;

if(~STATE.batch_process_running)
    h = waitbar(0,sprintf('Saving statistics to %s',filename_out));
end;
fprintf(fout,'Stage\tStage Dur(sec)\tArtifact Count\tArtifact Dur(sec)\tPct of stage(%%)\tPct of Artifact Dur(%%)\tPct of Artifact Count (%%)\r\n');


if(isempty(artifact_start_stops))
    starts = [];
    stops = [];
else
    starts = artifact_start_stops(:,1);
    stops = artifact_start_stops(:,2);
end

all_art_count = size(starts,1);
all_art_dur_sec = sum(stops-starts)/sample_rate;
artifact_start_epochs = sample2epoch(starts,BATCH_PROCESS.standard_epoch_sec,sample_rate);
artifact_start_stages = MARKING.sev_STAGES.line(artifact_start_epochs);

fprintf(fout,sprintf('All\t%0.1f\t%i\t%0.1f\t%0.2f\t100.0\t100.0\r\n',MARKING.study_duration_in_seconds,all_art_count,all_art_dur_sec,...
    all_art_dur_sec/MARKING.study_duration_in_seconds*100));

for k = 0:numel(MARKING.sev_STAGES.count)-1
    if(MARKING.sev_STAGES.count(k+1)>0)
        stage_artifact_indices = find(artifact_start_stages==k);
        stage_artifact_count = numel(stage_artifact_indices);
        
        if(isempty(artifact_start_stops))
            stage_starts = 0;
            stage_stops = 0;
        else
            stage_starts = artifact_start_stops(stage_artifact_indices,1);
            stage_stops = artifact_start_stops(stage_artifact_indices,2);
        end

        stage_artifact_dur_sec = sum(stage_stops-stage_starts)/sample_rate;
    else
        stage_artifact_count = 0;
        stage_artifact_dur_sec = 0;        
    end
    
    fprintf(fout,'%i\t%0.1f\t%i\t%0.1f\t%0.2f\t%0.2f\t%0.2f\r\n',...
        k,...    %stage
        MARKING.sev_STAGES.count(k+1)*BATCH_PROCESS.standard_epoch_sec,... %stage duration (sec)
        stage_artifact_count,... %artifact count
        stage_artifact_dur_sec,... %artifact duration (sec)
        max(0,stage_artifact_dur_sec/(MARKING.sev_STAGES.count(k+1)*BATCH_PROCESS.standard_epoch_sec)*100),...
        max(0,stage_artifact_dur_sec/all_art_dur_sec*100),...
        stage_artifact_count/all_art_count*100);
end

fclose(fout);

disp(['Individual study statistics saved to ' filename_out]);

if(~STATE.batch_process_running)
    saveStatsTallyToFile(handles); %always call this in batch mode - regardless of stats being called.
    disp([filename_out ' updated.']);
    waitbar(100,h,'Saving Done');
    delete(h);
end;

