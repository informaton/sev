%> @file CLASS_database.m
%> @brief Database development and interaction class.
% ======================================================================
%> @brief The class is designed for database development, functionality, and 
%> interaction with SEV.
%> @note: A MySQL database must be installed on the local host for class
%> instantiations to operate correctly.
% ======================================================================
classdef CLASS_database < handle

    properties
        %> @brief Structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        DBstruct;
        
    end
    
    methods(Abstract)
        % ======================================================================
        %> @brief Abstract method to create a mysql database and tables. 
        %> The method should be implemented in derived classes according to the 
        %> database desired.
        %> @param obj CLASS_database derived instance
        % =================================================================
        createDBandTables(obj)
    end
    
    methods
        % ======================================================================
        %> @brief Abstract method to open the database associated with the
        %derived class.
        %> @param obj CLASS_database derivded instance.
        % =================================================================
        function open(obj)
            mym('close');
            mym('open','localhost',obj.DBstruct.user,obj.DBstruct.password);
            mym(['USE ',obj.DBstruct.name]);
        end   
        
        % ======================================================================
        %> @brief Creates Medications_T table and populates it using the filename of medications provided.
        %> @param obj CLASS_database instance
        %> @param meds_filename Name of file containing medications for the cohort.
        %> @note Medications_T table is first dropped if it already exists.
        %> @note This function has only been implemented with WSC data and
        %> is biased toward WSC patient - study identifier conventions,
        % =================================================================
        function create_Medications_T(obj,meds_filename)
            % this builds the medication table using WSC meidcation list received from Simon Warby (most likely)
            %
            % Author: Hyatt Moore IV
            % created 4/13/2013
            
            tableName = 'Medications_T';

            obj.open();
            fclose all;
            
            fid = fopen(meds_filename,'r');
            firstLine = fgetl(fid);
            column_names = regexp(firstLine,'(\S+)','tokens');
            
            % frewind(fid);
            data=textscan(fid,repmat('%s',1,numel(firstLine)),'headerlines',0,'delimiter','\t');
            fclose(fid);
            
            
            %create the table
            %table create string
            TStr = sprintf('CREATE TABLE IF NOT EXISTS %s (patstudykey smallint unsigned not null,',tableName);
            column_names_db_string = 'patstudykey';
            
            for n=2:numel(column_names)
                name = char(column_names{n});
                TStr = sprintf('%s %s bool default null,',TStr,name);
                column_names_db_string = sprintf('%s,%s',column_names_db_string,name);
            end
            
            TStr = sprintf('%s PRIMARY KEY (PATSTUDYKEY))',TStr);
            
            
            mym(['DROP TABLE IF EXISTS ',tableName]);
            mym(TStr);
            
            nrows = numel(data{1});
            ncols = numel(column_names);
            for row = 1:nrows
                q = mym('select patstudykey from studyinfo_t where concat(patid,"_",studynum)="{S}"',data{1}{row});
                if(~isempty(q.patstudykey))
                    valuesStr = num2str(q.patstudykey);
                    
                    for col = 2:ncols
                        valuesStr = sprintf('%s,%c',valuesStr,data{col}{row});
                    end
                    mym(sprintf('insert into %s (%s) values (%s)',tableName,column_names_db_string,valuesStr));
                end
            end
        end

    end
    
    methods(Static)
        
        % ======================================================================
        %> @brief Helper function for opening the MySQL database using field values
        %> provided in dbStruct
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        function openDB(dbStruct)
            % Hyatt Moore, IV (< June, 2013)            
            mym('close');
            mym('open','localhost',dbStruct.user,dbStruct.password);
            mym(['USE ',dbStruct.name]);
        end
        
        % ======================================================================
        %> @brief MySQL helper function.  Updates fields values for the specified
        %> table of the currently open database.  This is a wrapper for the
        %> the mysql call UPDATE table_name SET field1=new-value1, field2=new-value2
        %> [WHERE Clause]
        %> @param tableName Name of the table to updated (string)        
        %> @param setFieldName (string)
        %> @param setFieldValues (array float)
        %> @param whereFieldName (string)
        %> @param whereFieldValues (integer)
        %> @note executes the mysql statement
        %> <i>UPDATE tableName SET setFieldName=setFieldValues(k) WHERE whereFieldName=whereFieldValues</i>
        function updateDBTableFieldValues(tableName, setFieldName, setFieldValues, whereFieldName, whereFieldValues)
            %UPDATE table_name SET field1=new-value1, field2=new-value2
            %[WHERE Clause]
            for k=1:numel(setFieldValues)
                updateStr = sprintf('update %s set %s=%6.3f where %s=%u',tableName,setFieldName,setFieldValues(k),whereFieldName,whereFieldValues(k));
                mym(updateStr);
            end
        end
        
        % ======================================================================
        %> @brief Builds a mysql database and sets up permissions to modify
        %> for the designated user.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        % =================================================================
        function create_DB(dbStruct)
            % Author: Hyatt Moore IV
            % Created 12/27/11
            %
            % Last Modified 1/5/12
            mym('open','localhost','root')
            
            %setup a user for this person
            mym(['GRANT ALL ON ',dbStruct.name,'.* TO ''',dbStruct.user,'''@''localhost'' IDENTIFIED BY ''',DBpassword,'''']);
            mym('close');
            
            
            
            %login as the new user ...
            mym('open','localhost',dbStruct.user,dbStruct.password);
            
            %make the database to use
            mym(['CREATE DATABASE IF NOT EXISTS ',dbStruct.name]);
            
            mym('CLOSE');            
            
        end
        
        % ======================================================================
        %> @brief This creates a DetectorInfo_T table based on the provided
        %> input arguments.  The DetectorInfo_T table stores SEV detector
        %> configurations which have been used to produce events stored in
        %> the events_T table.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)        
        % =================================================================
        function create_DetectorInfo_T(dbStruct)
            %detector_pathname = directory name that contains detection.inf settings
            %                    file
            % Created table name is 'DetectorInfo_T'
            % Author: Hyatt Moore IV
            % Last Edited 12/31/11
            %
            % edited 5/7/2012
            %
            %
            % edited 1/16/12:
            %
            %         relaced :insertStr(end) = ')';
            %         with  insertStr = [insertStr,'NULL)'];
            
            TableName = 'DetectorInfo_T';
            
            %testing
            % detector_pathname ='/Users/hyatt4/Documents/Sleep Project/Software/sev v.43 beta/+detection'
            
            mym('CLOSE');
            CLASS_database.open(dbStruct);
            
            createStr = ['CREATE TABLE IF NOT EXISTS ',TableName,...
                ' (DetectorId TINYINT(3) UNSIGNED NOT NULL AUTO_INCREMENT,',...
                'DetectorFilename VARCHAR(50),',...
                'DetectorLabel VARCHAR(50),',...
                'ConfigID TINYINT(3) UNSIGNED DEFAULT 0,',...
                'ConfigChannelLabels BLOB,',...
                'ConfigParamStruct BLOB,',...
                'PRIMARY KEY(DETECTORID))'];
            
            
            mym(['DROP TABLE IF EXISTS ',TableName]);
            mym(createStr);
            mym('CLOSE');
        end
        
        % ======================================================================
        %> @brief This creates the Events_T table based on the provided
        %> input arguments.  The Events_T table stores SEV (batch mode) generated events.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @param events_pathname Name of directory that contains .evt files (PTSD or WSC)
        %> @note If the event_pathname directory argument is supplied then the directory
        %> is parsed for evt files which are then loaded into the table.
        %> If events_pathname is not provided the Events_T table is still produced but
        %> it is not populated with events.            
        % =================================================================
        function create_Events_T(dbStruct, events_pathname)
            %this creates an Events_T table using the database supplied by input arguments.
            % Table name created is Events_T
            % Author: Hyatt Moore IV
            % Last Edited
            %9/26/12 - added column for sleep cycles - called Cycle, which contains the
            %NREM-REM cycle of the associated event/row.
            % 5/16/12 - made Params BLOB instead of TINYBLOB
            %1/2/12
            
            TableName = 'Events_T';
            CLASS_database.open(dbStruct);
            
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                'PatStudyKey SMALLINT UNSIGNED NOT NULL',...
                ', DetectorID TINYINT (3) UNSIGNED NOT NULL'...
                ', Start_sample INTEGER UNSIGNED NOT NULL',...
                ', Stop_sample INTEGER UNSIGNED NOT NULL',...
                ', Duration_seconds REAL UNSIGNED NOT NULL',...
                ', Epoch SMALLINT UNSIGNED NOT NULL',...
                ', Stage ENUM(''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'')',...
                ', Cycle TINYINT UNSIGNED DEFAULT 1',...
                ', Params BLOB DEFAULT NULL',...
                ', KEY (DetectorID)',...
                ', PRIMARY KEY (PatStudyKey,DetectorID,Start_sample))']);
            
            
            if(nargin>3 && ~isempty(events_pathname))
                
                %% Handle the event table
                dirStruct = dir(fullfile(events_pathname,'evt.*.txt'));
                if(~isempty(dirStruct))
                    %PTSD_format...
                    if(strcmp('PTSD',dbStruct.name))
                        expression = 'evt\.(?<PatID>[a-z_A-Z]+)(?<StudyNum>\d+)\.(?<method>[^\.]+)\.(?<DetectorConfigID>\d+)\.txt';
                        
                        %WSC evt.A0097_6 182831.LM_ferri.1.txt
                    elseif(strcmp('WSC',dbStruct.name))
                        expression = 'evt\.(?<PatID>[a-z_A-Z0-9]+)_(?<StudyNum>\d+)\s\d+\.(?<method>[^\.]+)\.(?<DetectorConfigID>\d+)\.txt';
                    else
                        expression  = '';
                    end
                    
                    filecount = numel(dirStruct);
                    filenames = cell(numel(dirStruct),1);
                    [filenames{:}] = dirStruct.name;
                    fCell = regexp(filenames,expression,'names'); %regexpi is not case sensitive...
                else
                    fCell = {};
                end
                
                
                
                if(numel(fCell)>0)
                    
                    %DetectorConfigID is parsed as a string, even though it is a
                    %SMALLINT
                    %Stage is an ENUM and needs to have apostrophes around it
                    preInsertStrNoParams = ['INSERT INTO ',TableName, ' (PatStudyKey, DetectorID, DetectorConfigID, '...
                        'Start_sample, Stop_sample, Duration_seconds, Epoch, Stage, Cycle) VALUES(',...
                        '%d,%d,%s,%d,%d,%0.3f,%d,''%d'',%d)'];
                    
                    preInsertStrWithParams = ['INSERT INTO ',TableName, ' (PatStudyKey, DetectorID, DetectorConfigID, '...
                        'Start_sample, Stop_sample, Duration_seconds, Epoch, Stage, Cycle, Params) VALUES(',...
                        '%d,%d,%s,%d,%d,%0.3f,%d,''%d'',%d,"{M}")'];
                    
                    mym('SET autocommit = 0');
                    
                    for k=1:filecount
                        if(~isempty(fCell{k})) % && ~strcmp(fCell{k}.method,'txt')) %SECOND PART is no longer necessary
                            x =mym(['SELECT PatStudyKey FROM StudyInfo_T WHERE PatID=''',...
                                fCell{k}.PatID,''' AND StudyNum=',fCell{k}.StudyNum]);
                            PatIDKey = x.PatStudyKey;
                            y = mym(['SELECT DetectorID FROM DetectorInfo_T WHERE Label=''',...
                                fCell{k}.method,''' LIMIT 1']);
                            DetectorID = y.DetectorID;
                            DetectorConfigID = fCell{k}.DetectorConfigID; %this is parsed as a string here because of the regexp call
                            evtStruct = evtTxt2evtStruct(fullfile(events_pathname,filenames{k}));
                            numEvts = numel(evtStruct.Start_sample);
                            if(isempty(evtStruct.Params))
                                for e=1:numEvts
                                    InsertStr = sprintf(preInsertStrNoParams,PatIDKey,DetectorID,DetectorConfigID,...
                                        evtStruct.Start_sample(e), evtStruct.Stop_sample(e),...
                                        evtStruct.Duration_seconds(e), evtStruct.Epoch(e),...
                                        evtStruct.Stage(e),evtStruct.Cycle(e));
                                    try
                                        mym(InsertStr);
                                    catch ME
                                        disp(ME);
                                    end
                                end
                            else
                                for e=1:numEvts
                                    InsertStr = sprintf(preInsertStrWithParams,PatIDKey,DetectorID,DetectorConfigID,...
                                        evtStruct.Start_sample(e), evtStruct.Stop_sample(e),...
                                        evtStruct.Duration_seconds(e), evtStruct.Epoch(e),...
                                        evtStruct.Stage(e),evtStruct.Cycle(e));
                                    try
                                        mym(InsertStr,evtStruct.Params(e));
                                    catch ME
                                        showME(ME);
                                    end
                                end
                            end
                        end
                    end
                    mym('COMMIT');
                    mym('SET autocommit = 1');
                    
                end
                
            end
            
            mym('CLOSE');
        end
        
        % ======================================================================
        %> @brief Creates Stages_T table based on the provided
        %> input arguments.  The Stages_T table stores sleep staging data for
        %> sleep studies (i.e. hypnograms)
        %> @param dbStruct Structure of database access fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        % =================================================================
        function create_Stages_T(dbStruct)
            % creates the STAGES_T table for the database identified by dbStruct.
            % If dbStruct information is not supplied then it is assumed that the
            % database has already been selected and is open for use
            % Written by Hyatt Moore IV
            % 4/20/2013
            CLASS_database.open(dbStruct);
            
            
            TableName = 'Stages_T';
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            %    ', Stage ENUM(''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''NREM'') NOT NULL'...
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                ' patstudykey SMALLINT UNSIGNED NOT NULL'...
                ', epoch SMALLINT UNSIGNED NOT NULL',...
                ', start_sample INTEGER UNSIGNED NOT NULL',...
                ', stage VARCHAR(2) DEFAULT "7"'...
                ', cycle TINYINT UNSIGNED DEFAULT ''0'''...
                ', duration_sec SMALLINT DEFAULT ''30'' '...
                ', fragment SMALLINT DEFAULT ''0'''...
                ', SO_start_sample SMALLINT DEFAULT ''0'''...
                ', PRIMARY KEY (PatStudyKey, start_sample)'...
                ')']);
            
            
            %fragmentation count is the number of times one stage is left for another
            
            if(nargin)
                mym('CLOSE');
            end
        end
        
        % ======================================================================
        %> @brief Creates StageStats_T table and populates it using input statistics.
        %> @param stats is a cell of stage structures as output by stage2stats.m file
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @note If dbStruct is not supplied (arg 2) then it is assumed that the
        %> database has already been selected and is open for use
        %> @note If StageStats_T already exists, it is first dropped and
        %> then created again.
        % =================================================================
        function create_StageStats_T(stats,dbStruct)
            %stats is a cell of stage structures as output by stage2stats.m file
            % TableName is the table name to load the cell of structures into
            % if DB information is not supplied (args 3-5) then it is assumed that the
            % database has already been selected and is open for use
            % Written by Hyatt Moore IV
            % modified 12.3.2012 to add nrem/rem cycle as field and primary key
            % modified 10.22.12 - check that patstudykey is not empty before continuing
            % with try to load database data
            if(nargin>=2)
                CLASS_database.open(dbStruct);
            end
            
            TableName = 'StageStats_T';
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            %    ', Stage ENUM(''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''NREM'') NOT NULL'...
            
            % helper code to rename the duration, etc.
            % mym('alter table stagestats_t change Duration duration_sec smallint default ''0''')
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                ' PatStudyKey SMALLINT UNSIGNED NOT NULL'...
                ', Stage VARCHAR(2) DEFAULT "7"'...
                ', Cycle TINYINT UNSIGNED DEFAULT ''0'''...
                ', Duration_sec SMALLINT DEFAULT ''0'' '...
                ', Count SMALLINT DEFAULT ''0'''...
                ', Pct_study DECIMAL (4,2) DEFAULT ''0'''...
                ', Pct_sleep DECIMAL (4,2) DEFAULT ''0'''...
                ', Fragmentation_count SMALLINT DEFAULT ''0'''...
                ', Latency SMALLINT DEFAULT ''0'''...
                ', PRIMARY KEY (PatStudyKey, Stage, cycle)'...
                ')']);
            
            %fragmentation count is the number of times one stage is left for another
            
            preInsertStr = ['INSERT INTO ',TableName, ' VALUES('];
            
            %starts the transaction
            % mym('START TRANSACTION');
            
            %This may work faster ...
            mym('SET autocommit=0');
            for k=1:numel(stats)
                %only need to do this query once, since each entry (1..numel(stats{k})
                %will have the same PatID and StudyNum field values
                if(~isempty(stats{k}))
                    %     PatStudyKey = num2str(mym(['SELECT PatStudyKey FROM StudyInfo_T WHERE PatID=''',stats{k}(1).PatID,''' AND StudyNum=''',stats{k}(1).StudyNum,''' LIMIT 1']));
                    x = mym(['SELECT PatStudyKey FROM StudyInfo_T WHERE PatID=''',stats{k}(1).PatID,''' AND StudyNum=''',stats{k}(1).StudyNum,''' LIMIT 1']);
                    PatStudyKey = num2str(x.PatStudyKey);
                    if(~isempty(PatStudyKey))
                        numStages = numel(stats{k});
                        if(numStages>0)
                            numCycles = numel(stats{k}(1).Stage);
                            for curStage=1:numel(stats{k})
                                for curCycle = 1:numCycles
                                    try
                                        InsertStr = [preInsertStr,PatStudyKey,...
                                            ',''',num2str(stats{k}(curStage).Stage(curCycle)),''',',...
                                            num2str(stats{k}(curStage).Cycle(curCycle)),',',...
                                            num2str(stats{k}(curStage).Duration(curCycle)),',',...
                                            num2str(stats{k}(curStage).Count(curCycle)),',',....
                                            num2str(stats{k}(curStage).Pct_study(curCycle)),',',...
                                            num2str(stats{k}(curStage).Pct_sleep(curCycle)),',',...
                                            num2str(stats{k}(curStage).Fragmentation_count(curCycle)),',',...
                                            num2str(stats{k}(curStage).Latency(curCycle)),...
                                            ')'];
                                        mym(InsertStr);
                                    catch me
                                        showME(me);
                                    end
                                end
                            end
                        end
                    end
                end
            end
            mym('COMMIT');
            mym('SET autocommit = 1');
            if(nargin>2)
                mym('CLOSE');
            end
        end
        
        % ======================================================================
        %> @brief Creates the StudyInfo_T table which stores meta data associated
        %> with a cohort of sleep studies.  The table is populated if a
        %> pathname to the cohort of sleep studies is supplied.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @param study_pathname Name of directory that contains .EDF files
        %> @note If the study_pathname argument is not supplied, the user is prompted to select
        %> a pathname via GUI dialog box.
        %> @note StudyInfo_T table is first dropped if it exists.
        % =================================================================
        function create_StudyInfo_T(dbStruct, study_pathname)
            %this creates a StudyInfo_T table based on the provided input arguments
            %study_pathname = name of directory that contains .EDF files that use WSC
            %naming convention: 'PatID_StudyNum HHMMSS.EDF'
            % Table name created is StudyInfo_T
            % Author: Hyatt Moore IV
            % Last Edited 12/27/11
            %               updated 7/17/12 - added visitSequence field
            
            TableName = 'StudyInfo_T';
            
            if(nargin<2)
                study_pathname = uigetdir(pwd,'Select Study (.EDF) directory');
            end
            
            if(~isempty(study_pathname))
                if(~ispc)
                    dirStruct = [dir(fullfile(study_pathname,'*.EDF'));dir(fullfile(study_pathname,'*.edf'))];
                else
                    dirStruct = dir(fullfile(study_pathname,'*.EDF'));
                end
                if(~isempty(dirStruct))
                    filecount = numel(dirStruct);
                    filenames = cell(numel(dirStruct),1);
                    [filenames{:}] = dirStruct.name;
                end
                
                %try WSC format first
                %example filename:    A0097_4 174733.STA
                exp = '(?<PatID>[a-zA-Z0-9]+)_(?<StudyNum>\d+)[^\.]+\.EDF';
                %     exp = '(?<PatID>[a-zA-Z0-9]+)_(?<studyNum>\d+)\s\d+\.STA';
                fCell= regexp(filenames,exp,'names'); %regexpi is not case sensitive...
                
                %might be PTSD format - so try it second
                if(numel(fCell)==0||isempty(fCell{1}))
                    expPTSD = '(?<PatID>[a-z]+)(?<StudyNum>\d+)[^\.]*\.edf';
                    fCell= regexpi(filenames,expPTSD,'names'); %regexpi is not case sensitive...
                end
                
                if(numel(fCell)>0)
                    CLASS_database.open(dbStruct);
                    mym('SET autocommit = 0');
                    mym(['DROP TABLE IF EXISTS ',TableName]);
                    mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                        ' PatStudyKey SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT'...
                        ', PatID VARCHAR(5) NOT NULL'...
                        ', StudyNum TINYINT (3) UNSIGNED NOT NULL'...
                        ', VisitSequence TINYINT(3) UNSIGNED NOT NULL'...
                        ', Montage_suite ENUM(''Grass'',''Gamma'',''Twin'',''Embla'',''Woodward'',''Unknown'') DEFAULT ''Grass'''...
                        ', PRIMARY KEY(PatStudyKey))']);
                    
                    preInsertStr = ['INSERT INTO ',TableName, ' (PatID, StudyNum, VisitSequence) VALUES('];
                    lastPatID = [];
                    VisitSequence = 1;
                    for k=1:filecount
                        if(~isempty(fCell{k})) % && ~strcmp(fCell{k}.method,'txt')) %SECOND PART is no longer necessary
                            PatID = fCell{k}.PatID;
                            StudyNum = fCell{k}.StudyNum;
                            
                            if(strcmp(PatID,lastPatID))
                                VisitSequence = VisitSequence+1;
                            else
                                VisitSequence = 1;
                            end
                            lastPatID = PatID;
                            InsertStr = [preInsertStr,'''',PatID,''',',...
                                num2str(StudyNum),',',num2str(VisitSequence),')'];
                            mym(InsertStr);
                        end
                    end
                    
                    mym('COMMIT');
                    mym('SET autocommit = 0');
                    
                end
            end
            
            mym('CLOSE');
            
        end
        
        % ======================================================================
        %> @brief Populates Events_T table using events found in the directory provided. 
        %> @param events_pathname Name of directory that contains SEV .evt.*.txt files 
        %> (i.e. the files with SEV formatted events).
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @note Regular expressions are used to determine the Cohort used
        %> based on the event file name format found in events_pathname.
        % =================================================================
        function populate_Events_T(events_pathname,dbStruct)
            % function populate_Events_T(events_pathname,DBname,DBuser,DBpassword)
            %this populates an Events_T table using the database supplied by input arguments.
            % If the event_pathname directory argument is supplied then the directory
            % is parsed for evt files which are then loaded into the table.
            %events_pathname = name of directory that contains .evt files (PTSD or WSC)
            % Table name created is Events_T
            % Author: Hyatt Moore IV
            % Last Edited 1/21/12
            
            TableName = 'Events_T';
            CLASS_database.open(dbStruct);
            
            if(nargin>1 && ~isempty(events_pathname))
                
                
                
                %% Handle the event table
                dirStruct = dir(fullfile(events_pathname,'evt.*.txt'));
                if(~isempty(dirStruct))
                    filecount = numel(dirStruct);
                    filenames = cell(numel(dirStruct),1);
                    [filenames{:}] = dirStruct.name;
                end
                
                
                
                %PTSD_format...
                if(strmatch('PTSD',dbStruct.name))
                    exp = 'evt\.(?<PatID>[a-z_A-Z]+)(?<StudyNum>\d+)\.(?<method>[^\.]+)\.(?<DetectorConfigID>\d+)\.txt';
                    
                    %WSC evt.A0097_6 182831.LM_ferri.1.txt
                elseif(strmatch('WSC',dbStruct.name))
                    exp = 'evt\.(?<PatID>[a-z_A-Z0-9]+)_(?<StudyNum>\d+)\s\d+\.(?<method>[^\.]+)\.(?<DetectorConfigID>\d+)\.txt';
                else
                    exp  = '';
                end
                
                fCell = regexp(filenames,exp,'names'); %regexpi is not case sensitive...
                
                if(numel(fCell)>0)
                    
                    %DetectorConfigID is parsed as a string, even though it is a
                    %SMALLINT
                    %Stage is an ENUM and needs to have apostrophes around it
                    preInsertStr = ['INSERT INTO ',TableName, ' (PatStudyKey, DetectorID, ConfigID, '...
                        'Start_sample, Stop_sample, Duration_seconds, Epoch, Stage) VALUES(',...
                        '%d,%d,%s,%d,%d,%0.3f,%d,''%d'')'];
                    
                    mym('SET autocommit = 0');
                    
                    numfiles = filecount;  %5000;
                    h = waitbar(0,'processing');
                    for k=1:filecount
                        waitbar(k/numfiles,h,[num2str(k),' - ',filenames{k}]);
                        drawnow();
                        if(~isempty(fCell{k})) % && ~strcmp(fCell{k}.method,'txt')) %SECOND PART is no longer necessary
                            x = mym(['SELECT PatStudyKey FROM StudyInfo_T WHERE PatID=''',...
                                fCell{k}.PatID,''' AND StudyNum=',fCell{k}.StudyNum]);
                            PatIDKey = x.PatStudyKey;
                            
                            y = mym(['SELECT DetectorID FROM DetectorInfo_T WHERE DetectorLabel=''',...
                                fCell{k}.method,''' LIMIT 1']);
                            
                            DetectorID = y.DetectorID;
                            DetectorConfigID = fCell{k}.DetectorConfigID; %this is parsed as a string here because of the regexp call
                            evtStruct = evtTxt2evtStruct(fullfile(events_pathname,filenames{k}));
                            
                            for e=1:numel(evtStruct.Start_sample)
                                InsertStr = sprintf(preInsertStr,PatIDKey,DetectorID,DetectorConfigID,...
                                    evtStruct.Start_sample(e), evtStruct.Stop_sample(e),...
                                    evtStruct.Duration_seconds(e), evtStruct.Epoch(e),...
                                    evtStruct.Stage(e));
                                try
                                    mym(InsertStr);
                                catch ME
                                    disp(ME.message);
                                end
                            end
                        end
                    end
                    mym('COMMIT');
                    mym('SET autocommit = 1');
                    
                end
                
            end
            
            mym('CLOSE');
            
        end
        
        % ======================================================================
        %> @brief Populates Detection_*_T table using the _configLegend_*.txt file
        %> found in the directory provided.
        %> @param events_pathname Name of directory that contains the _configLegend_*.txt file
        %> to be parsed for detector configurations.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @note %this creates a series of tables with the naming convention Detection_MethodName_T
        %> @note Table name(s) created is Detection_MethodNames_T as based on
        %> _configLegend_*.txt files in the events_pathname directory
        %> Contents of this file are an extraction of create_Events_T.  They were
        %> removed because problems would occur in this part and it is a pain to
        %> have to load all of the events again when there are a lot of them (i.e.
        %> time consuming).  In order to debug, this section needed to be examined,
        %> so I just went ahead and made it it's own file.
        % =================================================================
        function populate_Detection_Methods_T(events_pathname,dbStruct)
            %function create_Detection_Methods_T(events_pathname,DBname,DBuser,DBpassword)
            %this creates a series of tables with the naming convention Detection_MethodName_T            
            % Author: Hyatt Moore IV
            % Created 1/21/12
            
            CLASS_database.open(dbStruct);            
            
            %LOAD the configuration table entries into the Detetion_methodLabel_T
            %tables.  These are taken from _configLegend_methodLabel.txt files in
            %the same output/events directory produced by the SEV's batch mode.
            %     _configLegend_LM_ferri.txt
            dirStruct = dir(fullfile(events_pathname,'_configLegend_*.txt'));
            if(~isempty(dirStruct))
                filenames = cell(numel(dirStruct),1);
                [filenames{:}] = dirStruct.name;
                
                exp = '_configLegend_(?<method>[^\.]+)\.txt';
                fCell = regexp(filenames,exp,'names'); %regexpi is not case sensitive...
                
                if(~isempty(fCell))
                    for k=1:numel(fCell)
                        TableLabelName = ['Detection_',deblank(char(fCell{k}.method)),'_T'];
                        windows_filename = fullfile(events_pathname,filenames{k});
                        windows_filename(windows_filename=='\') = '/';
                        try
                            mym(['LOAD DATA LOCAL INFILE ''',windows_filename,''' INTO TABLE ',TableLabelName,...
                                ' LINES TERMINATED BY ''\r\n''',...
                                ' IGNORE 1 LINES']);
                        catch me
                            disp(me);
                        end
                    end
                end
            end
            
            mym('close');
            
        end
    
        % ======================================================================
        %> @brief Populates Stages_T table for the database identified by dbStruct
        %> using the staging files (.sta) located in the path 'sta_pathname'.
        %> If dbStruct information is not supplied then it is assumed that the
        %> database has already been selected and is open for useusing events found in the directory provided.
        %> @param sta_pathname Name of directory that contains staging (.STA) hypnogram files.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @note Regular expressions are used to determine the Cohort used
        %> based on the event file name format found in events_pathname.
        % =================================================================
        function populate_Stages_T(sta_pathname,dbStruct)
            % populates the STAGES_T table for the database identified by dbStruct
            % using the staging files (.sta) located in the path 'sta_pathname'.
            % If dbStruct information is not supplied then it is assumed that the
            % database has already been selected and is open for use
            % Written by Hyatt Moore IV
            % 4/20/2013
            if(nargin>1)
                openDB(dbStruct);
            end
            
            [sta_filenames,sta_fullfilenames] = getFilenames(sta_pathname,'*.STA2');
            
            %starts the transaction
            % mym('START TRANSACTION');
            
            %This may work faster ...
            mym('SET autocommit=0');
            samplerate = 100;
            for f=1:numel(sta_fullfilenames)
                sta_exp = '(?<patid>[a-zA-Z]+)(?<studynum>\d+)\.STA2';
                
                result= regexp(sta_filenames{f},sta_exp,'names');
                if(~isempty(result))
                    q = mym('select patstudykey as pkey from studyinfo_t where patid="{S}" and studynum={S}',result.patid,result.studynum);
                    key = q.pkey;
                    
                    STAGES = loadSTAGES2(sta_fullfilenames{f});
                    epochs = 1:numel(STAGES.line);
                    duration_sec = STAGES.standard_epoch_sec;
                    samples_per_epoch = duration_sec*samplerate;
                    
                    so_latency_samples = STAGES.firstNonWake*samples_per_epoch;
                    start_samples= (epochs-1)*samples_per_epoch+1;
                    so_latency_start_samples = start_samples+so_latency_samples;
                    for e=1:numel(epochs)
                        try
                            %key, epoch, start, stage, cycle, duration, fragment,
                            %so_start
                            mym(sprintf('Insert into STAGES_T values (%u,%u,%u,%u,%u,%u,%u,%u)',key,epochs(e),start_samples(e),...
                                STAGES.line(e),STAGES.cycles(e),duration_sec,STAGES.fragments(e),so_latency_start_samples(e)));
                        catch me
                            showME(me);
                        end
                        
                        
                    end
                end
            end
            mym('COMMIT');
            mym('SET autocommit = 1');
            if(nargin>1)
                mym('CLOSE');
            end
        end
        
        % ======================================================================
        %> @brief Populates StageStats_T the database identified by dbStruct
        %> and the provided @e stats structure 
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @param stats An array of structures containing stage statistics.
        %> @note @e stats can be built using the stage2stats.m file.
        %> Add comment to wiki as an issue if this file is not found with
        %> the SEV package.
        % =================================================================
        function populate_StageStats_T(dbStruct,stats)
            %stats is a cell of stage structures as output by stage2stats.m file
            
            % Written by Hyatt Moore IV
            %2.25.2013 -mostly taken from create_StageStats_t
            
            mym('open','localhost',dbStruct.user,dbStruct.password);
            mym(['USE ',dbStruct.name]);
            
            TableName = 'StageStats_T';
            % %    ', Stage ENUM(''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''NREM'') NOT NULL'...
            %
            % mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
            %     ' PatStudyKey SMALLINT UNSIGNED NOT NULL'...
            %     ', Stage VARCHAR(2) DEFAULT "7"'...
            %     ', Cycle TINYINT UNSIGNED DEFAULT ''0'''...
            %     ', Duration SMALLINT DEFAULT ''0'' '...
            %     ', Count SMALLINT DEFAULT ''0'''...
            %     ', Pct_study DECIMAL (4,2) DEFAULT ''0'''...
            %     ', Pct_sleep DECIMAL (4,2) DEFAULT ''0'''...
            %     ', Fragmentation_count SMALLINT DEFAULT ''0'''...
            %     ', Latency SMALLINT DEFAULT ''0'''...
            %     ', PRIMARY KEY (PatStudyKey, Stage, cycle)'...
            % ')']);
            
            %fragmentation count is the number of times one stage is left for another
            
            preInsertStr = ['INSERT INTO ',TableName, ' VALUES('];
            
            %starts the transaction
            % mym('START TRANSACTION');
            
            %This may work faster ...
            mym('SET autocommit=0');
            for k=1:numel(stats)
                %only need to do this query once, since each entry (1..numel(stats{k})
                %will have the same PatID and StudyNum field values
                if(~isempty(stats{k}))
                    %     PatStudyKey = num2str(mym(['SELECT PatStudyKey FROM StudyInfo_T WHERE PatID=''',stats{k}(1).PatID,''' AND StudyNum=''',stats{k}(1).StudyNum,''' LIMIT 1']));
                    x = mym(['SELECT PatStudyKey FROM StudyInfo_T WHERE PatID=''',stats{k}(1).PatID,''' AND StudyNum=''',stats{k}(1).StudyNum,''' LIMIT 1']);
                    PatStudyKey = num2str(x.PatStudyKey);
                    if(~isempty(PatStudyKey))
                        numStages = numel(stats{k});
                        if(numStages>0)
                            numCycles = numel(stats{k}(1).Stage);
                            for curStage=1:numel(stats{k})
                                for curCycle = 1:numCycles
                                    try
                                        InsertStr = [preInsertStr,PatStudyKey,...
                                            ',''',num2str(stats{k}(curStage).Stage(curCycle)),''',',...
                                            num2str(stats{k}(curStage).Cycle(curCycle)),',',...
                                            num2str(stats{k}(curStage).Duration(curCycle)),',',...
                                            num2str(stats{k}(curStage).Count(curCycle)),',',....
                                            num2str(stats{k}(curStage).Pct_study(curCycle)),',',...
                                            num2str(stats{k}(curStage).Pct_sleep(curCycle)),',',...
                                            num2str(stats{k}(curStage).Fragmentation_count(curCycle)),',',...
                                            num2str(stats{k}(curStage).Latency(curCycle)),...
                                            ')'];
                                        mym(InsertStr);
                                    catch me
                                        showME(me);
                                    end
                                end
                            end
                        end
                    end
                end
            end
            mym('COMMIT');
            mym('SET autocommit = 1');
            if(nargin>2)
                mym('CLOSE');
            end
            
        end
        
        % ======================================================================
        %> @brief Populates StudyInfo_T table for the database identified by dbStruct
        %> and the information found in EDF directory and montage suite provided.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @param edf_directory Name of directory that contains the .EDF sleep
        %> studies (string)
        %> @param montage_suite Sleep recording/collection suite identifier (string)
        %> @note montage_suite defaults to the string @b NULL if empty.
        %> @note Examples of montage suites include @e grass, @e twin, 
        %> and @e embla.
        % =================================================================
        function populate_StudyInfo_T(dbStruct, edf_directory,montage_suite)
            %populates the StudyInfo_T table using files in the given directory
            %dbStruct is a struct with the following fields
            % name = name of the database to use
            % user = user of the database
            % password = password for DBuser
            %patID_studynum_edf vector of files with the following
            %naming convention: 'PatID_StudyNum HHMMSS.EDF'
            % Author: Hyatt Moore IV
            % 10.21.2012
            % modified: 10.25.2012 - add the tmp_ prefix to handle numeric patID which
            % are not valid field names in MATLAB
            %modified 2/26/2013 - updated to match most recent create_StudyInfo_T.m
            
            TableName = 'StudyInfo_T';
            
            mym('open','localhost',dbStruct.user,dbStruct.password);
            mym(['USE ',dbStruct.name]);
            mym('SET autocommit = 0');
            edf_files = getFilenames(edf_directory,'*.EDF');
            
            
            if(nargin<3)
                montage_suite = 'NULL';
            end
            preInsertStr = ['INSERT INTO ',TableName, ' (PatID, StudyNum, VisitSequence, Montage_suite) '];
            
            for f=1:numel(edf_files)
                skip = false;
                patstudy = strrep(edf_files{f},'.EDF','');
                [PatID,StudyNum] = CLASS_events_container.getDB_PatientIdentifiers(patstudy);
                
                q=mym('select * from {S} where patid="{S}"',TableName,PatID);
                if(isempty(q.StudyNum))
                    visitSequence = 1;
                else
                    if(StudyNum>q.StudyNum(end))
                        visitSequence = q.VisitSequence(end)+1;
                    else
                        visitSequence = 0;
                        skip = true;
                        fprintf('********Major problem with %s_%u********\n',PatID,str2double(StudyNum));
                    end
                end
                %
                if(~skip)
                    InsertStr = sprintf('%s values ("%s",%u,%u,"%s")',preInsertStr,PatID,str2double(StudyNum),visitSequence,montage_suite);
                    mym(InsertStr);
                end
            end
            
            
            mym('COMMIT');
            mym('SET autocommit = 0');
            
            
            mym('CLOSE');
            
        end
        
    end        
       
    
end

