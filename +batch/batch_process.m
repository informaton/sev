function MARKING = batch_process(pathname, BATCH_PROCESS,playlist, MARKING)
    %this function executes the batch job with the specified parameters
    
    %default to all - i.e. process all .edf's found in pathname
    if(nargin<4)
        MARKING = [];
    end

    if(nargin<3)
        playlist = [];
    end    
    
    %why does this need to be persistent?
    persistent log_fid;
    
    % BATCH_PROCESS.output_path =
    %        parent: 'output'
    %           roc: 'ROC'
    %         power: 'PSD'
    %        events: 'events'
    %     artifacts: 'artifacts'
    %        images: 'images'
    %       current: '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/output'
    %this is a given since the button is not activated unless an EDF is
    %found in the current directory
    
    if(pathname)
        if ~isempty(MARKING)
            MARKING.SETTINGS.BATCH_PROCESS.edf_folder = pathname;
            MARKING.STATE.batch_process_running = true;
        end
        
        %     file_list = dir([fullfile(path, '*.EDF');fullfile(path, '*.edf')]);
        %pc's do not have a problem with case; unfortunately the other side
        %does
        %     if(ispc)
        %         file_list = dir(fullfile(pathname,'*.EDF'));
        %     else
        %         file_list = [dir(fullfile(pathname, '*.EDF'));  dir(fullfile(pathname, '*.edf'))]; %dir(fullfile(path, '*.EDF'))];
        %     end
        file_list = dir(fullfile(pathname,'*.EDF'));
        if(~isempty(playlist))
            file_list = filterPlaylist(file_list, playlist);
        end
        
        %reference sev.m - sev_OpeningFcn (line ~192)
        BATCH_PROCESS.output_path.current = fullfile(BATCH_PROCESS.output_path.parent);
        
        % waitHandle = waitbar(0,'Initializing batch processing job','name','Batch Processing Statistics','resize','on','createcancelbtn',{@cancel_batch_Callback});
        user_cancelled = false;
        waitHandle = waitbar(0,'Initializing job','name','Batch Processing','resize','on','createcancelbtn',@cancel_batch_Callback,'userdata',user_cancelled,'tag','waitbarHTag');
        
        BATCH_PROCESS.waitHandle = waitHandle;
        %turn off the interpeter so that '_' does not cause subscripting
        set(findall(waitHandle,'interpreter','tex'),'interpreter','none');
        
        waitbarPos = get(waitHandle,'position');
        waitbarPos(4)=waitbarPos(4)*1.5;
        set(waitHandle,'position',waitbarPos);
        
        file_count = numel(file_list);
        
        if(~isdir(BATCH_PROCESS.output_path.current))
            mkdir(BATCH_PROCESS.output_path.current);
        end
        
        full_roc_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.roc);
        if(~isdir(full_roc_path))
            mkdir(full_roc_path);
        end
        
        full_psd_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.power);
        if(~isdir(full_psd_path))
            mkdir(full_psd_path);
        end
        full_events_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.events);
        if(~isdir(full_events_path))
            mkdir(full_events_path)
        end
        full_events_images_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.events,BATCH_PROCESS.output_path.images);
        if(~isdir(full_events_images_path))
            mkdir(full_events_images_path);
        end
        full_artifacts_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.artifacts);
        if(~isdir(full_artifacts_path))
            mkdir(full_artifacts_path);
        end
        full_artifacts_images_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.artifacts,BATCH_PROCESS.output_path.images);
        if(~isdir(full_artifacts_images_path))
            mkdir(full_artifacts_images_path);
        end        
        
        if(BATCH_PROCESS.output_files.log_checkbox)
            BATCH_PROCESS.start_time = datestr(now,'yyyymmmdd_HH_MM_SS');
            log_filename = fullfile(BATCH_PROCESS.output_path.current,[BATCH_PROCESS.output_files.log_filename,BATCH_PROCESS.start_time,'.txt']);
            log_fid = fopen(log_filename,'w');
            
            fprintf(log_fid,'SEV batch process run on %i files.\r\n',file_count);
            if(numel(BATCH_PROCESS.event_settings)>0)
                
                fprintf(log_fid,'The following event detectors were run with this batch job.\r\n');
                for k=1:numel(BATCH_PROCESS.event_settings)
                    method_label = char(BATCH_PROCESS.event_settings{k}.method_label);
                    pStruct = BATCH_PROCESS.event_settings{k}.pBatchStruct;
                    channel_labels = reshape(char(BATCH_PROCESS.event_settings{k}.channel_labels)',1,[]);
                    batch_mode_label = char(BATCH_PROCESS.event_settings{k}.batch_mode_label);
                    
                    fprintf(log_fid,'%u.\t%s\t(labeled as ''%s'')\tApplied to Channel(s): %s',k,method_label,batch_mode_label,channel_labels);
                    
                    %put one of these two in the log file
                    if(numel(pStruct)>0)
                        fprintf(log_fid,'\t(Parameter, start, stop, num steps):');
                        for c=1:numel(pStruct)
                            fprintf(log_fid,' %s(%d,%d,%d)',pStruct{c}.key,pStruct{c}.start,pStruct{c}.stop,pStruct{c}.num_steps);
                        end
                    else
                        params = BATCH_PROCESS.event_settings{k}.params;
                        if(~isempty(params))
                            keys =fieldnames(params);
                            fprintf(log_fid,'\tParameter(value):');
                            for c=1:numel(keys)
                                fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                            end
                        else
                            fprintf(log_fid,' No adjustable settings for this method');
                        end
                    end
                    fprintf(log_fid,'\r\n');
                end
            else
                fprintf(log_fid,'No event detectors were run with this batch job.\r\n');
            end
            if(numel(BATCH_PROCESS.artifact_settings)>0)
                fprintf(log_fid,'The following artifact detectors were run with this batch job.\r\n');
                
                for k=1:numel(BATCH_PROCESS.artifact_settings)
                    method_label = char(BATCH_PROCESS.artifact_settings{k}.method_label);
                    params = BATCH_PROCESS.artifact_settings{k}.params;
                    channel_labels = reshape(char(BATCH_PROCESS.artifact_settings{k}.channel_labels)',1,[]);
                    batch_mode_label = char(BATCH_PROCESS.artifact_settings{k}.batch_mode_label);
                    
                    fprintf(log_fid,'%u.\t%s\t(labeled as ''%s'')\tApplied to Channel(s): %s',k,method_label,batch_mode_label,channel_labels);
                    
                    if(~isempty(params))
                        keys =fieldnames(params);
                        fprintf(log_fid,'\tParameter(value):');
                        for c=1:numel(keys)
                            fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                        end
                    else
                        fprintf(log_fid,' No adjustable settings for this method');
                    end
                    fprintf(log_fid,'\r\n');                    
                end
            else
                fprintf(log_fid,'No artifact detectors were run with this batch job.\r\n');
            end
            
            if(numel(BATCH_PROCESS.PSD_settings)>0)
                fprintf(log_fid,'Power spectral density by periodogram analysis was conducted with the following configuration(s):\r\n');
                for k=1:numel(BATCH_PROCESS.PSD_settings)
                    params = BATCH_PROCESS.PSD_settings{k};
                    fprintf(log_fid,'%u.\t',k);
                    
                    if(~isempty(params))
                        fprintf(log_fid,'Parameter(value):\t');
                        keys =fieldnames(params);
                        for c=numel(keys):-1:1
                            switch(class(params.(keys{c})))
                                case 'double'
                                    fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                                case 'cell'
                                    fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}){1});
                                case 'char'
                                    fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}));
                                otherwise
                                    fprintf(log_fid,' %s(unknownType)',keys{c});
                            end
                        end
                    else
                        fprintf(log_fid,' No adjustable settings for this method');
                    end
                    fprintf(log_fid,'\r\n');
                end
            end
            
            if(numel(BATCH_PROCESS.MUSIC_settings)>0)
                fprintf(log_fid,'Power spectral density by MUSIC analysis was conducted with the following configuration(s):\r\n');
                for k=1:numel(BATCH_PROCESS.MUSIC_settings)
                    params = BATCH_PROCESS.MUSIC_settings{k};
                    fprintf(log_fid,'%u.\t',k);
                    if(~isempty(params))
                        keys =fieldnames(params);
                        fprintf(log_fid,'Parameter(value):\t');
                        for c=numel(keys):-1:1
                            switch(class(params.(keys{c})))
                                case 'double'
                                    fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                                case 'cell'
                                    fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}){1});
                                case 'string'
                                    fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}));
                                otherwise
                                    fprintf(log_fid,' %s(unknownType)',keys{c});
                            end
                        end
                    else
                        fprintf(log_fid,' No adjustable settings for this method');
                    end
                    fprintf(log_fid,'\r\n');
                end
            end
            fprintf(log_fid,'Job was started: %s\r\n\r\n',BATCH_PROCESS.start_time);
        else
            disp('No log file created for this run.  Choose settings to change this, and check the log checkbox if you want to change this.');
            BATCH_PROCESS.start_time = ' ';
        end
        
        event_settings = BATCH_PROCESS.event_settings;
        artifact_settings = BATCH_PROCESS.artifact_settings;
        
        image_settings =[];
        if(BATCH_PROCESS.images.save2img)
            image_settings.limit_count = BATCH_PROCESS.images.limit_count*BATCH_PROCESS.images.limit_flag;
            image_settings.buffer_sec = BATCH_PROCESS.images.buffer_sec*BATCH_PROCESS.images.buffer_flag;
            image_settings.format = BATCH_PROCESS.images.format;
            for k = 1:numel(event_settings)
                if(event_settings{k}.save2img)
                    %put images in subdirectory based on detection method
                    event_images_path = fullfile(full_events_images_path,event_settings{k}.method_label);
                    if(~isdir(event_images_path))
                        mkdir(event_images_path);
                    end
                end
            end
            for k = 1:numel(artifact_settings)
                if(artifact_settings{k}.save2img)
                    %put images in subdirectory based on detection method
                    artifact_images_path = fullfile(full_events_images_path,artifact_settings{k}.method_label);
                    if(~isdir(artifact_images_path))
                        mkdir(artifact_images_path);
                    end
                end
            end
        end
        
        for k = 1:numel(event_settings)
            method_label = event_settings{k}.method_label;
            
            pBatchStruct = event_settings{k}.pBatchStruct;
            paramStruct = event_settings{k}.params;
            event_settings{k}.numConfigurations = 1;
            %grid out the combinations here...and reassign to pBatchStruct
            if(~isempty(pBatchStruct))
                
                num_keys = numel(pBatchStruct); %this is the number of distinct settings that can be manipulated for the current (k) event detector
                all_properties = cell(num_keys,1);
                keys = cell(size(all_properties));
                
                %determine the range of values to go
                %through for each property value
                %allowed/specified
                clear pStruct;
                for j = 1:num_keys
                    keys{j} = pBatchStruct{j}.key;
                    pStruct.(keys{j}) = [];
                    if(isnumeric(pBatchStruct{j}.start))
                        %add this check in here, otherwise a user may change
                        %the start value, leaving the num steps one, but the
                        %start value is less than the end value and linspace
                        %will instead return the lesser value, and not
                        %what the user wants in this case
                        if(pBatchStruct{j}.num_steps==1)
                            all_properties{j} = pBatchStruct{j}.start;
                        else
                            all_properties{j} = linspace(pBatchStruct{j}.start,pBatchStruct{j}.stop,pBatchStruct{j}.num_steps);
                        end
                    else
                        if(strcmp(pBatchStruct{j}.start,pBatchStruct{j}.stop))
                            all_properties{j} = pBatchStruct{j}.start;
                        else
                            all_properties{j} = {pBatchStruct{j}.start,pBatchStruct{j}.stop};
                        end
                    end
                end
                cell_all_properties = cell(size(all_properties));
                [cell_all_properties{:}] = ndgrid(all_properties{:}); %grid it out, with all combinations...
                
                numConfigurations = numel(cell_all_properties{1});
                pStructArray = repmat(pStruct,numConfigurations,1);
                
                for j = 1:numConfigurations
                    for p = 1:num_keys
                        pStructArray(j).(keys{p}) = cell_all_properties{p}(j);
                    end
                end
                event_settings{k}.numConfigurations = numConfigurations;
                if(~BATCH_PROCESS.database.save2DB)
                    event_settings{k}.configID = 1:numConfigurations;
                end
                event_settings{k}.params = pStructArray;                
            end
            
            %this saves the detector configurations for each detector to a
            %separate file, with an id for each cconfiguration setup that can
            %be used to determine which file output is for which configuration
            if(~isempty(paramStruct))
                batch.saveDetectorConfigLegend(full_events_path,method_label,event_settings{k}.params);
            end
        end
        
        %% setup database for events
        if(BATCH_PROCESS.database.save2DB)
            %database_struct contains fields 'name','user','password' for interacting with a mysql database
            DBstruct = CLASS_database_psg.loadDatabaseStructFromInf(BATCH_PROCESS.database.filename,BATCH_PROCESS.database.choice);
            if(~isempty(DBstruct))
                DBstruct.table = 'events_t';
                if(BATCH_PROCESS.database.auto_config~=0||BATCH_PROCESS.database.config_start==0)
                    event_settings = CLASS_database_psg.getDatabaseAutoConfigID(DBstruct,event_settings);
                else
                    event_settings = CLASS_database_psg.setDatabaseConfigID(DBstruct,event_settings,BATCH_PROCESS.database.config_start);
                end
                event_settings = CLASS_database_psg.deleteDatabaseRecordsUsingSettings(DBstruct,event_settings);
            end
        else
            DBstruct = [];
        end        
        
        BATCH_PROCESS.event_settings = event_settings;        
        
        %% Begin batch file processing  - parallel computing parfor
        %     parfor i = 1:file_count - need to update global calls to work
        %     better here.
        
        startClock = clock;
        files_attempted = false(file_count,1);
        files_completed = false(file_count,1);
        files_skipped = false(file_count,1); %logical indices to mark which files were skipped
        
        
        start_time = now;
        %     est_str = '?'; %estimate of how much time is left to run the job
        
        % user_cancelled = get(waitHandle,'userdata');
        
        clear configID;
        clear detectorID;
        clear elapsed_dur_total_sec;
        
        %     if(BATCH_PROCESS.output_files.log_checkbox && ~isempty(log_fid))
        %         fclose(log_fid);
        %     end
        assignin('base','files_completed',files_completed);
        
        %MATLAB pool open ?
        
        try
            %     matlabpool open
        catch me
            showME(me)
        end
        %     parfor i = 1:file_count
        
        for i = 1:file_count
            tStart = tic;
            configID = [];
            detectorID = [];
            user_cancelled = false;
            %       waitHandle = findall(0,'tag','waitbarHTag');            
            
            if(~user_cancelled)                
                try
                    
                    %             if(BATCH_PROCESS.output_files.log_checkbox)
                    %                 log_filename = fullfile(BATCH_PROCESS.output_path.current,[BATCH_PROCESS.output_files.log_filename,BATCH_PROCESS.start_time,'.txt']);
                    %                 log_fid = fopen(log_filename,'w');
                    %             end
                    if(~file_list(i).isdir)
                        files_attempted(i) = 1;
                        
                        %initialize the files...
                        %                 tStart = clock;
                        cur_filename = file_list(i).name;
                        
                        skip_file = false;
                        
                        %                 BATCH_PROCESS.cur_filename = cur_filename;
                        stages_filename = fullfile(pathname,[cur_filename(1:end-3) 'STA']);
                        
                        if(~exist(stages_filename,'file'))
                            stages_filename = fullfile(pathname,[cur_filename(1:end-3) 'evts']);
                        end
                        
                        %require stages filename to exist.
                        if(~exist(stages_filename,'file'))
                            
                            skip_file = true;
                            
                            %%%%%%%%%%%%%%%%%%%%%REVIEW%%%%%%%%%%%%%%%%%%%%%%%%
                            %                     if(BATCH_PROCESS.output_files.log_checkbox)
                            %                         fprintf(log_fid,'%s not found!  This EDF will be skipped.\r\n',stages_filename);
                            %                     end
                        end
                        
                        if(~skip_file)
                            
                            
                            %this loads the channels specified in the BATCH_PROCESS
                            %variable, for the current EDF file
                            
                            %CREATES A GLOBAL CHANNELS_CONTAINER CLASS FOR THIS
                            %iteration/run
                            [batch_CHANNELS_CONTAINER, parBATCH_PROCESS, studyInfo] = batch.load_file(pathname,cur_filename, BATCH_PROCESS);
                            %the following two settings need to follow batch.load
                            %due the side effects that occur in batch.load_file
                            %that change the event_settings to include new field
                            %channel_indices which may change per EDF loaded as the
                            %naming convention should/must remain the same, while
                            %the channel numbering/ordering does not have the same
                            %requirement
                            artifact_settings = parBATCH_PROCESS.artifact_settings;
                            event_settings = parBATCH_PROCESS.event_settings;
                            %handle the stage data, which is a requirement for
                            %batch processing - that is, it must exist for batch
                            %processing to continue/work
                            %                     batch_STAGES = loadSTAGES(stages_filename,studyInfo.num_epochs);
                            %                     unknown_stage=7; %can add this as
                            %                     a third parameter below.
                            batch_STAGES = CLASS_codec.loadSTAGES(stages_filename,studyInfo.num_epochs);
                            batch_STAGES.startDateTime = studyInfo.startDateTime;
                            
                            %PROCESS ARTIFACTS
                            batch_ARTIFACT_CONTAINER = CLASS_events_container([],[],parBATCH_PROCESS.base_samplerate,batch_STAGES); %this global variable may be checked in output functions and
                            batch_ARTIFACT_CONTAINER.CHANNELS_CONTAINER = batch_CHANNELS_CONTAINER;
                            artifact_filenames = fullfile(full_artifacts_path,[parBATCH_PROCESS.output_files.artifacts_filename,cur_filename(1:end-4)]);
                            
                            %this requires initialization
                            
                            if(numel(artifact_settings)>0)
                                for k = 1:numel(artifact_settings)
                                    
                                    function_name = artifact_settings{k}.method_function;
                                    %                             function_call = [detection_path,'.',function_name];
                                    
                                    source_indices = artifact_settings{k}.channel_indices;
                                    
                                    detectStruct = batch_ARTIFACT_CONTAINER.evaluateDetectFcn(function_name,source_indices, artifact_settings{k}.params);
                                    
                                    %                             detectStruct = feval(function_call,source_indices,params);
                                    sourceStruct = [];
                                    sourceStruct.channel_indices = source_indices;
                                    sourceStruct.algorithm = function_name;
                                    sourceStruct.editor = 'none';
                                    if(~isempty(detectStruct.new_events))
                                        
                                        batch_ARTIFACT_CONTAINER.addEvent(detectStruct.new_events,artifact_settings{k}.method_label,0,sourceStruct,detectStruct.paramStruct);
                                        if(artifact_settings{k}.save2img)
                                            
                                            %put these images in their own subdirectory based on
                                            %patients identifier
                                            artifact_images_path = fullfile(full_artifacts_images_path,cur_filename(1:end-4));
                                            if(~isdir(artifact_images_path))
                                                mkdir(artifact_images_path);
                                            end
                                            img_filename_prefix = [cur_filename(1:end-4),'-',artifact_settings{k}.method_label];
                                            full_img_filename_prefix = fullfile(artifact_images_path,img_filename_prefix);
                                            batch_ARTIFACT_CONTAINER.save2images(k,full_img_filename_prefix,image_settings);
                                        end
                                        
                                    else %add empty
                                        %                         events as well so that we can show what was and
                                        %                         was not met in the periodogram output...
                                        batch_ARTIFACT_CONTAINER.addEmptyEvent(artifact_settings{k}.method_label,0,sourceStruct,detectStruct.paramStruct);
                                        
                                    end
                                    batch_ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_label = artifact_settings{k}.batch_mode_label;
                                    
                                end
                                if(BATCH_PROCESS.output_files.save2mat)
                                    batch_ARTIFACT_CONTAINER.save2mat(artifact_filenames);
                                end
                                if(BATCH_PROCESS.database.save2DB)
                                    batch_ARTIFACT_CONTAINER.save2DB(artifact_filenames);
                                end
                                if(BATCH_PROCESS.output_files.save2txt)
                                    batch_ARTIFACT_CONTAINER.save2txt(artifact_filenames);
                                end
                            end
                            
                            
                            %PROCESS THE EVENTS
                            if(numel(event_settings)>0)
                                batch_EVENT_CONTAINER = CLASS_events_container([],[],parBATCH_PROCESS.base_samplerate,batch_STAGES);
                                batch_EVENT_CONTAINER.CHANNELS_CONTAINER = batch_CHANNELS_CONTAINER;
                                event_filenames = fullfile(full_events_path,[parBATCH_PROCESS.output_files.events_filename,cur_filename(1:end-4)]);
                                
                                for k = 1:numel(event_settings)
                                    function_name = event_settings{k}.method_function;
                                    %                             function_call = [detection_path,'.',function_name];
                                    
                                    pBatchStruct = event_settings{k}.pBatchStruct;
                                    
                                    %there are no combinations to use....
                                    if(isempty(pBatchStruct))
                                        source_indices = event_settings{k}.channel_indices;
                                        detectStruct = batch_EVENT_CONTAINER.evaluateDetectFcn(function_name, source_indices, event_settings{k}.params);
                                        if(~isempty(detectStruct.new_events))
                                            sourceStruct = [];
                                            sourceStruct.channel_indices = source_indices;
                                            sourceStruct.algorithm = function_name;
                                            sourceStruct.editor = 'none';
                                            sourceStruct.pStruct = [];
                                            
                                            %add the event
                                            batch_EVENT_CONTAINER.addEvent(detectStruct.new_events,event_settings{k}.method_label,source_indices,sourceStruct,detectStruct.paramStruct);
                                            batch_EVENT_CONTAINER.getCurrentChild.batch_mode_label = event_settings{k}.batch_mode_label;
                                            
                                            batch_EVENT_CONTAINER.getCurrentChild.configID = event_settings{k}.configID;
                                            batch_EVENT_CONTAINER.getCurrentChild.detectorID = event_settings{k}.detectorID;
                                            
                                            
                                            %                                     if(~isempty(event_settings{k}.params)) %in this case, configurationLegend.detection_method.txt file was created
                                            %                                         configID = 1;
                                            %                                     else
                                            %                                         configID = 0; %this is the default anyway...-> no file was created
                                            %                                     end
                                            %
                                            %                                     EVENT_CONTAINER.cell_of_events{EVENT_CONTAINER.num_events}.configID = configID;
                                            
                                            if(event_settings{k}.save2img)
                                                %put these images in their own subdirectory based on
                                                %patients identifier
                                                event_images_path = fullfile(full_events_images_path,event_settings{k}.method_label);
                                                
                                                
                                                img_filename_prefix = [cur_filename(1:end-4),'_',event_settings{k}.method_label];
                                                full_img_filename_prefix = fullfile(event_images_path,img_filename_prefix);
                                                batch_EVENT_CONTAINER.save2images(k,full_img_filename_prefix,image_settings);
                                            end
                                        end
                                        
                                        %alternate case is to create and add an event
                                        %for each pStruct combination possible from the
                                        %given pBatchStruct parameters.
                                    else
                                        start_evt_ind = batch_EVENT_CONTAINER.num_events +1;
                                        for j = 1:event_settings{k}.numConfigurations;
                                            pStruct = event_settings{k}.params(j);
                                            source_indices = event_settings{k}.channel_indices;
                                            detectStruct = batch_EVENT_CONTAINER.evaluateDetectFcn(function_name, source_indices, pStruct);
                                            %                                     detectStruct = feval(function_call,source_indices,pStruct);
                                            try
                                                configID = event_settings{k}.configID(j);
                                                if(~isempty(event_settings{k}.detectorID))
                                                    detectorID = event_settings{k}.detectorID(j);
                                                end
                                            catch me
                                                showME(me);
                                            end
                                            if(~isempty(detectStruct.new_events))
                                                sourceStruct.channel_indices = source_indices;
                                                sourceStruct.algorithm = function_name;
                                                sourceStruct.editor = 'none';
                                                sourceStruct.pStruct = pStruct;
                                                batch_EVENT_CONTAINER.addEvent(detectStruct.new_events,event_settings{k}.method_label,source_indices,sourceStruct,detectStruct.paramStruct);
                                                batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.batch_mode_label = event_settings{k}.batch_mode_label;
                                                batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.configID = configID;
                                                batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.batch_mode_label = event_settings{k}.batch_mode_label;
                                                batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.detectorID = detectorID;
                                            end
                                        end
                                        end_evt_ind = batch_EVENT_CONTAINER.num_events;
                                        
                                        if(~isempty(event_settings{k}.rocStruct))
                                            if(end_evt_ind>=start_evt_ind)  %make sure I didn't go through and get nothing...
                                                rocStruct = event_settings{k}.rocStruct;
                                                truth_file = dir(fullfile(rocStruct.truth_pathname,['*.',cur_filename(1:end-3),'*',rocStruct.truth_evt_suffix]));
                                                if(~isempty(truth_file))
                                                    truth_filename = fullfile(rocStruct.truth_pathname,truth_file(1).name);
                                                    if(exist(truth_filename,'file'))
                                                        if ~isempty(MARKING)
                                                            batch_EVENT_CONTAINER.loadEvtFile(truth_filename,MARKING.STATE.batch_process_running);
                                                        end
                                                        
                                                        %add this check here since the EVENT_CONTAINER will not load the event from a file if it was previously
                                                        %loaded.  Without this check, the roc may produce 100% matches since it would be comparing to itself
                                                        if(batch_EVENT_CONTAINER.num_events~=end_evt_ind)
                                                            batch_EVENT_CONTAINER.roc_truth_ind = batch_EVENT_CONTAINER.num_events;
                                                        end
                                                        save_filename = fullfile(full_roc_path,['ROC_',rocStruct.truth_evt_suffix,'_VS_',function_name,'.txt']);
                                                        if(i==1 && exist(save_filename,'file'))
                                                            delete(save_filename);
                                                        end
                                                        batch_EVENT_CONTAINER.save2roc_txt(save_filename,[start_evt_ind,end_evt_ind],rocStruct.truth_evt_suffix,cur_filename);
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                if(BATCH_PROCESS.output_files.save2mat)
                                    batch_EVENT_CONTAINER.save2mat(event_filenames);
                                end
                                if(BATCH_PROCESS.database.save2DB)
                                    batch_EVENT_CONTAINER.save2DB(DBstruct,cur_filename(1:end-4)); %database_struct contains fileds 'name','user','password' for interacting with a mysql database
                                end
                                if(BATCH_PROCESS.output_files.save2txt)
                                    batch_EVENT_CONTAINER.save2txt(event_filenames);
                                end
                                
                            end
                            
                            %SAVE THINGS TO FILE....
                            %save the events to file... - this is now handled in
                            %save_periodograms.m now
                            %AGAIN - THIS IS NOW HANDLED IN SAVE_PERIODOGRAMS.M
                            %                     if(BATCH_PROCESS.output_files.cumulative_stats_checkbox)
                            %                          batch.updateBatchStatisticsTally();
                            %                     end
                            
                            %this is handled in batch/save_periodograms.m now
                            %                     if(BATCH_PROCESS.output_files.statistics_checkbox) %artifact statistics
                            % %                         save_art_stats_Callback(hObject, eventdata, handles);
                            %                           batch.saveArtifactandStageStatistics();
                            %                     end
                            for k = 1:numel(parBATCH_PROCESS.PSD_settings)
                                channel_label = parBATCH_PROCESS.PSD_settings{k}.channel_labels{:};
                                channel_index = parBATCH_PROCESS.PSD_settings{k}.channel_indices;
                                filename_out = fullfile(full_psd_path,[cur_filename(1:end-3), channel_label,'.', parBATCH_PROCESS.output_files.psd_filename]);
                                batch.save_periodograms(batch_CHANNELS_CONTAINER.getChannel(channel_index),batch_STAGES,parBATCH_PROCESS.PSD_settings{k},filename_out,batch_ARTIFACT_CONTAINER,parBATCH_PROCESS.start_time);
                            end
                            
                            for k = 1:numel(parBATCH_PROCESS.MUSIC_settings)
                                channel_label = parBATCH_PROCESS.MUSIC_settings{k}.channel_labels{:};
                                channel_index = parBATCH_PROCESS.MUSIC_settings{k}.channel_indices;
                                filename_out = fullfile(full_psd_path,[cur_filename(1:end-3), channel_label,'.', parBATCH_PROCESS.output_files.music_filename]);
                                batch.save_pmusic(batch_CHANNELS_CONTAINER.getChannel(channel_index),batch_STAGES,parBATCH_PROCESS.MUSIC_settings{k},filename_out,batch_ARTIFACT_CONTAINER,parBATCH_PROCESS.start_time);
                            end
                            
                            %save the files to disk
                            if(BATCH_PROCESS.output_files.log_checkbox)
                                if(~isempty(fopen(log_fid)))
                                    fprintf(log_fid,'%s . . . completed successfully at %s\r\n',file_list(i).name,datestr(now));
                                end
                            end
                            
                        else
                            if(BATCH_PROCESS.output_files.log_checkbox)
                                %                         fprintf(log_fid,'%s . . . NOT PROCESSED (see notes above)\r\n',file_list(i).name);
                            end
                            
                            files_skipped(i) = true;
                        end
                        files_completed(i) = true;
                        elapsed_dur_sec = toc(tStart);
                        fprintf('File %d of %d (%0.2f%%) Completed in %0.2f seconds\n',i,file_count,i/file_count*100,elapsed_dur_sec);
                        elapsed_dur_total_sec = etime(clock,startClock);
                        avg_dur_sec = elapsed_dur_total_sec/i;
                        
                        %                 num_files_completed = randi(1,0,100);
                        num_files_completed = i;
                        remaining_dur_sec = avg_dur_sec*(file_count-num_files_completed);
                        est_str = sprintf('%01ihrs %01imin %01isec',floor(mod(remaining_dur_sec/3600,24)),floor(mod(remaining_dur_sec/60,60)),floor(mod(remaining_dur_sec,60)));
                        
                        msg = {['Processing ',file_list(i).name, ' (file ',num2str(i) ,' of ',num2str(file_count),')'],...
                            ['Time Elapsed Time: ',datestr(now-start_time,'HH:MM:SS')],...
                            ['Estimated Time Remaining: ',est_str]};
                        fprintf('%s\n',msg{2});
                        if(ishandle(waitHandle))
                            waitbar(i/file_count,waitHandle,char(msg));
                        else
                            %                     waitHandle = findall(0,'tag','waitbarHTag');
                        end
                        
                    end
                catch cur_error
                    %             showME(cur_error);
                    disp([file_list(i).name, ' SKIPPED: The following error was encountered: (' cur_error.message ')']);
                    file_warnmsg = cur_error.message;
                    showME(cur_error);
                    
                    %             console_warnmsg = cur_error.message;
                    %             for s = 1:min(numel(cur_error.stack),2)
                    %                 % disp(['<a href="matlab:opentoline(''',file,''',',linenum,')">Open Matlab to this Error</a>']);
                    %                 stack_error = cur_error.stack(s);
                    %                 console_warnmsg = sprintf('%s\r\n\tFILE: %s <a href="matlab:opentoline(''%s'',%s)">LINE: %s</a> FUNCTION: %s', console_warnmsg,stack_error.file,stack_error.file,num2str(stack_error.line),num2str(stack_error.line), stack_error.name);
                    %                 file_warnmsg = sprintf('\t%s\r\n\t\tFILE: %s LINE: %s FUNCTION: %s', file_warnmsg,stack_error.file,num2str(stack_error.line), stack_error.name);
                    %             end
                    %             disp(console_warnmsg)
                    
                    if(BATCH_PROCESS.output_files.log_checkbox)
                        if(~isempty(fopen(log_fid)))
                            fprintf(log_fid,'%s . . . NOT PROCESSED.  The following error was encountered:\r\n%s\r\n',file_list(i).name,file_warnmsg);
                        end
                    end
                    files_skipped(i)= true;
                    files_completed(i) = true;
                    
                    
                    elapsed_dur_sec = toc(tStart);
                    fprintf('File %d of %d (%0.2f%%) Completed in %0.2f seconds\n',i,file_count,i/file_count*100,elapsed_dur_sec);
                    elapsed_dur_total_sec = etime(clock,startClock);
                    avg_dur_sec = elapsed_dur_total_sec/i;
                    remaining_dur_sec = avg_dur_sec*(file_count-i);
                    est_str = sprintf('%01ihrs %01imin %01isec',floor(mod(remaining_dur_sec/3600,24)),floor(mod(remaining_dur_sec/60,60)),floor(mod(remaining_dur_sec,60)));
                    
                    msg = {['Processing ',file_list(i).name, ' (file ',num2str(i) ,' of ',num2str(file_count),')'],...
                        ['Elapsed Time: ',datestr(now-start_time,'HH:MM:SS')],...
                        ['Estimated Time Remaining: ',est_str]};
                    
                    if(ishandle(waitHandle))
                        fprintf('You finished recently!\n');
                        waitbar(i/file_count,waitHandle,char(msg));
                    else
                        %                 waitHandle = findall(0,'tag','waitbarHTag');
                    end
                end
            else
                
                files_skipped(i) = true;
            end %end if not batch_process.cancelled
        end %end for all files
        
        %     matlabpool close;
        
        num_files_completed = sum(files_completed);
        num_files_skipped = sum(files_skipped);
        %     waitHandle = findobj('tag','waitbarTag');
        
        finish_str = {'SEV batch process completed!',['Files Completed = ',...
            num2str(num_files_completed)],['Files Skipped = ',num2str(num_files_skipped)],...
            ['Elapsed Time: ',datestr(now-start_time,'HH:MM:SS')]};
        
        if(ishandle(waitHandle))
            waitbar(100,waitHandle,finish_str);
        end
        
        if(BATCH_PROCESS.output_files.log_checkbox)
            if(~isempty(fopen(log_fid)))
                fprintf(log_fid,'Job finished: %s\r\n',datestr(now));
                fclose(log_fid);
            end
        end
        if ~isempty(MARKING)
            [log_path,log_filename,log_file_ext] = fileparts(MARKING.SETTINGS.VIEW.parameters_filename);
            MARKING.SETTINGS.saveParametersToFile([],fullfile(BATCH_PROCESS.output_path.current,[log_filename,log_file_ext]));
        
            %not really necessary, since I am not going to update the handles after
            %this function call in order for everything to go back to what it was
            %before hand ...;
            
            MARKING.STATE.batch_process_running = false;
        end
        %     message = sprintf('Batch Processing finished.\r\n%i files attempted.\r\n%i files processed successfully.\r\n%i files skipped.',...
        %         num_files_attempted,num_files_completed,files_skipped);
        message = finish_str;
        
        if(num_files_skipped>0)
            skipped_filenames = cell(num_files_skipped,1);
            [skipped_filenames{:}]=file_list(files_skipped).name;
            [selections,clicked_ok]= listdlg('PromptString',message,'Name','Batch Completed',...
                'OKString','Copy to Clipboard','CancelString','Close','ListString',skipped_filenames);
            
            if(clicked_ok)
                %char(10) is newline
                skipped_files = [char(skipped_filenames(selections)),repmat(char(10),numel(selections),1)];
                skipped_files = skipped_files'; %filename length X number of files
                
                clipboard('copy',skipped_files(:)'); %make it a column (1 row) vector
                disp([num2str(numel(selections)),' filenames copied to the clipboard.']);
            end
        else
            msgbox(message,'Completed');
        end
        
        if(exist('waitHandle','var')&&ishandle(waitHandle))
            delete(waitHandle(1));
        end
        
    else
        disp 'nothing selected'
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%