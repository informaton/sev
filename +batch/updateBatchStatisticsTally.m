function updateBatchStatisticsTally(sample_rate,start_stops)
% updateBatchStatisticsTally(sample_rate,start_stops)
%handle the total number of aggragate statistics for each person
%good for batch processing and keeping track of each individuals statistics
%as saved to the file name shown below
%
%sample_rate is the sample_rate of the channel associated with start_stops
%start_stops is a 2-column matrix of start and stop sample points
%of artifact occuring

%Hyatt Moore, IV (< June,2013)
% June 13, 2013: The presence of global variables here indicates that this
% function has not been utilized in some time and likely needs updating in
% keeping with SEV's design changes.
global WORKSPACE;
global BATCH_PROCESS;
global DEFAULTS;
global STAGES;


filename_out = BATCH_PROCESS.output_files.cumulative_stats_filename;
fout = fopen(fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.artifacts,filename_out),'a');

%if the file did not already exists
if(ftell(fout)==0)
    fprintf(fout,'ID\tAll_Dur\tAll_ArtCount\tAll_ArtDur\tAll_Art%%Stage\tAll_%%ArtDur\tAll_%%ArtCount');
    for k = 0:numel(STAGES.count)-1
        fprintf(fout,'\tS%i_Dur\tS%i_ArtCount\tS%i_ArtDur\tS%i_Art%%Stage\tS%i_%%ArtDur\tS%i_%%ArtCount',k,k,k,k,k,k);
    end;
end;


starts = start_stops(:,1);
stops =  start_stops(:,2);
all_art_count = numel(starts);

all_art_dur_sec = sum(stops-starts)/sample_rate;
start_epochs = sample2epoch(starts,DEFAULTS.standard_epoch_sec,sample_rate);
start_stages = STAGES.line(start_epochs);


fprintf(fout,sprintf('\r\n%s\t%0.1f\t%i\t%0.1f\t%0.2f\t100.0\t100.0',BATCH_PROCESS.cur_filename,...
    WORKSPACE.study_duration_in_seconds,all_art_count,all_art_dur_sec,...
    all_art_dur_sec/WORKSPACE.study_duration_in_seconds*100)); %100 for 100percent

for k = 0:numel(STAGES.count)-1
    if(STAGES.count(k+1)>0)
        stage_indices = find(start_stages==k);
        stage_count = numel(stage_indices);
        if(isempty(start_stops))
            stage_starts = 0;
            stage_stops = 0;
        else
            stage_starts = start_stops(stage_indices,1);
            stage_stops = start_stops(stage_indices,2);
        end
        
        stage_dur_sec = sum(stage_stops-stage_starts)/sample_rate;
    else
        stage_count = 0;
        stage_dur_sec = 0;
    end
    
    
    fprintf(fout,'\t%i\t%i\t%0.1f\t%0.1f\t%0.2f\t%0.2f',STAGES.count(k+1)*DEFAULTS.standard_epoch_sec,...
        stage_count,stage_dur_sec,...
        max(0,stage_dur_sec/(STAGES.count(k+1)*DEFAULTS.standard_epoch_sec)*100),...
        max(0,stage_dur_sec/all_art_dur_sec*100),stage_count/all_art_count*100);
end
fclose(fout);

