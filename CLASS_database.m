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
        dbStruct;
        
    end
    
    
    methods(Abstract)
        % ======================================================================
        %> @brief Abstract method to create a mysql database and tables. 
        %> The method should be implemented in derived classes according to the 
        %> database desired.
        %> @param obj CLASS_database derived instance
        % =================================================================
        createDBandTables(obj);
        
        % ======================================================================
        %> @brief Abstract method to create a mysql database table, Diagnostics_T. 
        %> The method should be implemented in derived classes according to the 
        %> database desired.
        %> @param obj CLASS_database derived instance
        % =================================================================
        create_Diagnostics_T(obj);
    end
    
    methods
        % ======================================================================
        %> @brief Abstract method to open the database associated with the
        %> derived class.
        %> @param obj CLASS_database derivded instance.
        % =================================================================
        function open(obj)
            obj.openDB(obj.dbStruct);
        end  
        
        % ======================================================================
        %> @brief Builds a mysql database and sets up permissions to modify
        %> for the designated user.
        %> @param obj Instance of CLASS_database
        % =================================================================
        function create_DB(obj)
            % Author: Hyatt Moore IV
            % Created 12/27/11
            %
            % Last Modified 1/5/12
            mym('open','localhost','root')
            
            %setup a user for this person
            mym(['GRANT ALL ON ',obj.dbStruct.name,'.* TO ''',obj.dbStruct.user,'''@''localhost'' IDENTIFIED BY ''',obj.dbStruct.password,'''']);
            mym('close');
            
            
            
            %login as the new user ...
            mym('open','localhost',obj.dbStruct.user,obj.dbStruct.password);
            
            %make the database to use
            mym(['DROP DATABASE IF EXISTS ',obj.dbStruct.name]);
            mym(['CREATE DATABASE IF NOT EXISTS ',obj.dbStruct.name]);
            
            mym('CLOSE');            
            
        end
        
        % ======================================================================
        %> @brief Creates StageStats_T table and populates it for WSC using
        %> stage files found in the directory provided.
        %> @param obj Instance of CLASS_database
        %> @param STA_pathname Directory containing .STA hypnograms, the staging
        %> files for WSC sleep studies (string)
        %> @note If StageStats_T already exists, it is first dropped and
        %> then created again.
        % =================================================================
        function create_and_populate_StageStats_T(obj,STA_pathname)
            if(nargin<2 || isempty(STA_pathname))
                STA_pathname =uigetdir(pwd,'Select Stage Directory (*.STA) to use');
            end            
            sta_exp = '(?<PatID>[a-zA-Z0-9]+)_(?<StudyNum>\d+)[^\.]+\.STA';            
            if(isempty(STA_pathname))
                stats = CLASS_database.stage2stats([],sta_exp);
            else
                stats = CLASS_database.stage2stats(STA_pathname,sta_exp);
            end            
            CLASS_database.static_create_StageStats_T(obj.dbStruct);            
            CLASS_database.populate_StageStats_T(stats,obj.dbStruct);
        end
        
        % ======================================================================
        %> @brief Dumps the identified table to a text file using the same
        %> name and a '.txt' extension.
        %> @param obj Instance of CLASS_database
        %> @param tableName Name of the table (as a string) which will be
        %> dumped as a tab-delimited text file with one record per row.
        % ======================================================================
        function dumpTable2Text(obj, tableName)
            outFile = fullfile(pwd,strcat(tableName,'.txt'));
            obj.open();
            mym('select * from {S} INTO OUTFILE ''{S}''',tableName,outFile);            
        end
        

        
    end
    
    methods(Static)
        
        function close()
            mym('close');
        end
        
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
            TableName = lower(TableName);
            
            %testing
            % detector_pathname ='/Users/hyatt4/Documents/Sleep Project/Software/sev v.43 beta/+detection'
            
            mym('CLOSE');
            CLASS_database.openDB(dbStruct);
            
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
            TableName = lower(TableName);
            CLASS_database.openDB(dbStruct);
            
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
                            x =mym(['SELECT PatStudyKey FROM studyinfo_t WHERE PatID=''',...
                                fCell{k}.PatID,''' AND StudyNum=',fCell{k}.StudyNum]);
                            PatIDKey = x.PatStudyKey;
                            y = mym(['SELECT DetectorID FROM detectorinfo_t WHERE Label=''',...
                                fCell{k}.method,''' LIMIT 1']);
                            DetectorID = y.DetectorID;
                            DetectorConfigID = fCell{k}.DetectorConfigID; %this is parsed as a string here because of the regexp call
                            evtStruct = CLASS_events_container.evtTxt2evtStruct(fullfile(events_pathname,filenames{k}));
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
            CLASS_database.openDB(dbStruct);
            
            
            TableName = 'Stages_T';
            TableName = lower(TableName);
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
        function static_create_StageStats_T(dbStruct)
            %stats is a cell of stage structures as output by stage2stats.m file
            % TableName is the table name to load the cell of structures into
            % if DB information is not supplied (args 3-5) then it is assumed that the
            % database has already been selected and is open for use
            % Written by Hyatt Moore IV
            % modified 12.3.2012 to add nrem/rem cycle as field and primary key
            % modified 10.22.12 - check that patstudykey is not empty before continuing
            % with try to load database data
            CLASS_database.openDB(dbStruct);
            
            TableName = 'StageStats_T';
            TableName = lower(TableName);
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
        %> @note montage_suite defaults to the string @b Unknown if empty.
        %> @note Examples of montage suites include @e WSC, @e Grass, @e Gamma, @e Twin, @e Embla, @e Woodward, @e WSC, and @e Unknown {default}'
        %> @note If no montage_type is given, the default is 'Unknown'
        %> @note If the study_pathname argument is not supplied, the user is prompted to select        
        %> a pathname via GUI dialog box.        
        % =================================================================
        function populate_StudyInfo_T(dbStruct, edf_directory,montage_suite)
            % Author: Hyatt Moore IV
            % 10.21.2012
            % modified: 10.25.2012 - add the tmp_ prefix to handle numeric patID which
            % are not valid field names in MATLAB
            %modified 2/26/2013 - updated to match most recent create_StudyInfo_T.m

            TableName = lower('StudyInfo_T');
            
            if(nargin<3 || isempty(montage_suite))
                montage_suite = 'Unknown';
            end            
            
            if(nargin<2)
                edf_directory = uigetdir(pwd,'Select Study (.EDF) directory');
            end            
            
            if(~isempty(edf_directory))
                edf_files = getFilenames(edf_directory,'*.EDF');
                
                CLASS_database.openDB(dbStruct);
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
        
        
        % ======================================================================
        %> @brief Creates the StudyInfo_T table which stores meta data associated
        %> with a cohort of sleep studies.  The table is populated if a
        %> pathname to the cohort of sleep studies is supplied.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @note StudyInfo_T table is first dropped if it exists.
        % =================================================================
        function create_StudyInfo_T(dbStruct)
            %this creates a StudyInfo_T table based on the provided input arguments
            %study_pathname = name of directory that contains .EDF files that use WSC
            %naming convention: 'PatID_StudyNum HHMMSS.EDF'
            % Table name created is StudyInfo_T
            % Author: Hyatt Moore IV
            % Last Edited 12/27/11
            %               updated 7/17/12 - added visitSequence field
            
            TableName = 'StudyInfo_T';
            TableName = lower(TableName);
            
            
            CLASS_database.openDB(dbStruct);
            mym('SET autocommit = 0');
            mym(['DROP TABLE IF EXISTS ',TableName]);
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                ' PatStudyKey SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT'...
                ', PatID VARCHAR(8) NOT NULL'...
                ', StudyNum TINYINT (3) UNSIGNED NOT NULL'...
                ', VisitSequence TINYINT(3) UNSIGNED NOT NULL'...
                ', Montage_suite ENUM(''Grass'',''Gamma'',''Twin'',''Embla'',''Woodward'',''Unknown'',''APOE'',''WSC'') DEFAULT ''Unknown'''...
                ', PRIMARY KEY(PatStudyKey))']);
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
            TableName = lower(TableName);
            CLASS_database.openDB(dbStruct);
            
            if(nargin>1 && ~isempty(events_pathname))
                
                
                
                %% Handle the event table
                dirStruct = dir(fullfile(events_pathname,'evt.*.txt'));
                if(~isempty(dirStruct))
                    filecount = numel(dirStruct);
                    filenames = cell(numel(dirStruct),1);
                    [filenames{:}] = dirStruct.name;
                
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
                        preInsertStr = ['INSERT INTO ',TableName, ' (PatStudyKey, DetectorID, '...
                            'Start_sample, Stop_sample, Duration_seconds, Epoch, Stage) VALUES(',...
                            '%d,%d,%d,%d,%0.3f,%d,''%d'')'];
                        
                        mym('SET autocommit = 0');
                        
                        numfiles = filecount;  %5000;
                        h = waitbar(0,'processing');
                        axes_title_h = get(get(h,'children'),'title');
                        set(axes_title_h,'interpreter','none');  %turn off annoying underscore to subscripting business.
                        for k=1:filecount
                            waitbar(k/numfiles,h,[num2str(k),' - ',filenames{k}]);
                            drawnow();
                            if(~isempty(fCell{k})) % && ~strcmp(fCell{k}.method,'txt')) %SECOND PART is no longer necessary
                                x = mym(['SELECT PatStudyKey FROM studyinfo_t WHERE PatID=''',...
                                    fCell{k}.PatID,''' AND StudyNum=',fCell{k}.StudyNum]);
                                PatIDKey = x.PatStudyKey;
                                
                                y = mym(['SELECT DetectorID FROM detectorinfo_t WHERE DetectorLabel=''',...
                                    fCell{k}.method,''' LIMIT 1']);
                                
                                DetectorID = y.DetectorID;
                                evtStruct = CLASS_events_container.evtTxt2evtStruct(fullfile(events_pathname,filenames{k}));
                                
                                for e=1:numel(evtStruct.Start_sample)
                                    InsertStr = sprintf(preInsertStr,PatIDKey,DetectorID,...
                                        evtStruct.Start_sample(e), evtStruct.Stop_sample(e),...
                                        evtStruct.Duration_seconds(e), evtStruct.Epoch(e),...
                                        evtStruct.Stage(e));
                                    try
                                        mym(InsertStr);
                                    catch ME
                                        showME(ME);
                                    end
                                end
                            end
                        end
                        mym('COMMIT');
                        mym('SET autocommit = 1');
                        
                    end
                else
                    disp('No events found.');
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
            
            CLASS_database.openDB(dbStruct);            
            
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
                CLASS_database.openDB(dbStruct);
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
                            mym(sprintf('Insert into stages_t values (%u,%u,%u,%u,%u,%u,%u,%u)',key,epochs(e),start_samples(e),...
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
        %> @param stats An array of structures containing stage statistics.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @note @e stats can be built using the stage2stats.m file.
        %> Add comment to wiki as an issue if this file is not found with
        %> the SEV package.
        % =================================================================
        function populate_StageStats_T(stats,dbStruct)
            %stats is a cell of stage structures as output by stage2stats.m file
            
            % Written by Hyatt Moore IV
            %2.25.2013 -mostly taken from create_StageStats_t
            
             CLASS_database.openDB(dbStruct);
            
            TableName = 'StageStats_T';
            TableName = lower(TableName);

            
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
                    x = mym(['SELECT PatStudyKey FROM studyinfo_t WHERE PatID=''',stats{k}(1).PatID,''' AND StudyNum=''',stats{k}(1).StudyNum,''' LIMIT 1']);
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
        %> @brief Obtains a unique configuration ID for event detector configuration 
        %> as obtained from the unique labels that exist and are passed
        %> through.  A new configID is searched for beginning from
        %> first_configID.  Once a a configID is obtained for the provided settings (either a new ID in the case of
        %> a new configuration or the ID of an existing configuration that
        %> has the same settings entered) it is inserted into the
        %> DetectionInfo_T table.
        %> @note connfigID updates/incremennts based on the initial first_configID for each detection
        %> label used.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @param event_settings A structure of the event detector
        %> configuration with the following fields:
        %> @li @c channel_labels: {'C3-M2'}
        %> @li @c method_function: 'detection_artifact_hp_20hz
        %> @li @c method_label: 'artifact_hp_20hz
        %> @li @c params: [1x1 struct]
        %> @li @c configID: 0
        %> @li @c detectorID: 1 or []
        %> @param first_configID Integer to start finding/creating
        %> configuration ID's from.  The configID found or created by this method will be greater than or
        %> equal to the value of first_configID
        %> @retval event_settings A structure of the event detector
        %> configuration with the following fields:
        %> @li @c channel_labels: {'C3-M2'}
        %> @li @c method_function: 'detection_artifact_hp_20hz
        %> @li @c method_label: 'artifact_hp_20hz
        %> @li @c params: [1x1 struct]
        %> @li @c configID: 0
        %> @li @c detectorID: 1 or []
        %> @note Events with a new configID are removed from events_T if they exist to avoid possible duplication of configID's with stored events.
        %> @note A new record is added to DetectorInfO_T if configID does not currently exist.
        function event_settings = setDatabaseConfigID(dbStruct,event_settings,first_configID)
        
            mym_status = mym();
            if(mym_status~=0) %0 when mym is open and reachable (connected)
                CLASS_database.openDB(dbStruct);
            end
            
            %obtain the unique labels that exist and are passed through,
            %and are checked for reuse with each unique label one at a time so configID will
            %update based on the initial first_configID for each detection
            %label used.
            evts = cell2mat(event_settings);
            unique_detection_labels = unique(cells2cell(evts.method_label));
            for d=1:numel(unique_detection_labels)
                detect_label = unique_detection_labels{d};
                cur_config = first_configID;
                for k=1:numel(event_settings)
                    if(strcmp(detect_label,event_settings{k}.method_label))
                        detectStruct = event_settings{k};
                        event_settings{k}.configID = zeros(event_settings{k}.numConfigurations,1);
                        
                        for config=1:event_settings{k}.numConfigurations
                            event_settings{k}.configID(config) = cur_config;
                            detectStruct.configID = cur_config;
                            detectStruct.params = event_settings{k}.params(config);
                            q = mym('select detectorid from detectorinfo_t where detectorlabel="{S}" and configID={Si}',detect_label,cur_config);
                            detectorID = q.detectorid;
                            if(isempty(detectorID))
                                %insert it into the database now
                                detectStruct.detectorID = [];
                            else
                                detectStruct.detectorID = detectorID;
                            end
                            CLASS_database.insertDatabaseDetectorInfoRecord(dbStruct,detectStruct);
                            cur_config = cur_config+1;
                        end
                    end
                end
            end
            if(mym_status~=0)
                mym('close');
            end
            
            
        end

        % ======================================================================
        %> @brief Retrieves the database configurtion ID associated with event_settings.  
        %> If no match is found in the database table detectorInfo_T for event_settings then a 
        %> a new, unique configurationID (configID) is set in and returned with the output structure event_settings.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @param event_settings A structure of the event detector
        %> configuration with the following fields:
        %> @li @c channel_labels: {'C3-M2'}
        %> @li @c method_function: 'detection_artifact_hp_20hz
        %> @li @c method_label: 'artifact_hp_20hz
        %> @li @c params: [1x1 struct]
        %> @li @c configID: 0
        %> @li @c detectorID: 1 or []
        %> @retval event_settings A structure of the event detector
        %> configuration with the following fields:
        %> @li @c channel_labels: {'C3-M2'}
        %> @li @c method_function: 'detection_artifact_hp_20hz
        %> @li @c method_label: 'artifact_hp_20hz
        %> @li @c params: [1x1 struct]
        %> @li @c configID: 0
        %> @li @c detectorID: 1 or []
        function event_settings = getDatabaseAutoConfigID(dbStruct,event_settings)
            if(~isempty(dbStruct))
                mym_status = mym();
                if(mym_status~=0) %0 when mym is open and reachable (connected)
                    CLASS_database.openDB(dbStruct);
                end
                for k=1:numel(event_settings)
                    %                     Q = mym('SELECT DetectorID as detectorID FROM DetectorInfo_T WHERE DetectorLabel="{S}"',event_settings{k}.method_label);
                    Q = mym('SELECT detectorID, configID, ConfigChannelLabels, configparamstruct as param FROM detectorinfo_t WHERE DetectorLabel="{S}" order by configid',event_settings{k}.method_label);
                    
                    %if no detectorID is found, then it is new, will be autoupdated, and the
                    %configID should be 1 since it will be the first
                    %configuration
                    if(isempty(Q.detectorID))
                        event_settings{k}.configID = 1:event_settings{k}.numConfigurations;
                    else
                        %this method will also work, but need to find out
                        %what is maximum configID still when the
                        %query is empty, which would require another query
                        %                         mym('select * from detectorinfo_t where configparamstruct="{M}"',event_settings{k}.params)
                        
                        for ch=1:numel(event_settings{k}.channel_configs)
                            if(isempty(event_settings{k}.channel_configs{ch}))
                                event_settings{k}.channel_configs{ch} = event_settings{k}.channel_labels{ch};
                            end
                        end
                        
                        %detectStruct (detectorStruct) must have these fields:
                        %   .channel_labels: {'C3-M2'}
                        %   .channel_configs: {'C3-M2'} nor {[1x1 struct]}
                        %   .method_function: 'detection_artifact_hp_20hz
                        %   .method_label: 'artifact_hp_20hz
                        %   .params: [1x1 struct]
                        %   .configID: 1
                        %   .detectorID: 1 or []
                        detectStruct.channel_labels = event_settings{k}.channel_labels;
                        detectStruct.channel_configs = event_settings{k}.channel_configs;
                        detectStruct.method_function = event_settings{k}.method_function;
                        detectStruct.method_label = event_settings{k}.method_label;
                        detectStruct.detectorID = event_settings{k}.detectorID;
                        
                        event_settings{k}.configID = zeros(event_settings{k}.numConfigurations,1);
                        for config=1:event_settings{k}.numConfigurations
                            %determine if the configuration already exists, and
                            %if so, use the matching configID for that
                            %configuration
                            for j=1:numel(Q.param)
                                if(isequal(Q.param{j},event_settings{k}.params(config)))
                                    if(isequal(Q.ConfigChannelLabels{j},event_settings{k}.channel_configs)) %event_settings{k}.channel_labels))
                                        event_settings{k}.configID(config) = Q.configID(j);
                                    end
                                end
                            end
                            
                            %if no matches were found, then update to use the
                            %configID that falls next in line, by one, from the
                            %list of possible configID's.
                            if(event_settings{k}.configID(config)==0)
                                Q.configID(end+1) = Q.configID(end)+1; %increment the last configuration value
                                event_settings{k}.configID(config)=Q.configID(end); %so it can be assigned to this new setting
                                
                                detectStruct.configID = event_settings{k}.configID(config);
                                detectStruct.params = event_settings{k}.params(config);
                                %insert it into the database now
                                CLASS_events_container.insertDatabaseDetectorInfoRecord(dbStruct,detectStruct);
                            end
                        end
                    end
                end
                if(mym_status~=0)
                    mym('close');
                end
            end
            
        end
        
        % ======================================================================
        %> @brief Removes trieves the database configurtion ID associated with event_settings.  
        %> If no match is found in the database table detectorInfo_T for event_settings then a 
        %> a new, unique configurationID (configID) is set in and returned with the output structure event_settings.
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @li @c table Database table to remove records from (e.g.
        %> events_T)
        %> @param event_settings A structure of the event detector
        %> configuration with the following fields:
        %> @li @c channel_labels: {'C3-M2'}
        %> @li @c method_function: 'detection_artifact_hp_20hz
        %> @li @c method_label: 'artifact_hp_20hz
        %> @li @c params: [1x1 struct]
        %> @li @c configID: 0
        %> @li @c detectorID: 1 or []
        %> @retval event_settings A structure of the event detector
        %> configuration with the following fields:
        %> @li @c channel_labels: {'C3-M2'}
        %> @li @c method_function: 'detection_artifact_hp_20hz
        %> @li @c method_label: 'artifact_hp_20hz
        %> @li @c params: [1x1 struct]
        %> @li @c configID: 0
        %> @li @c detectorID: 1 or []
        function event_settings = deleteDatabaseRecordsUsingSettings(dbStruct,event_settings)
            if(~isempty(dbStruct))
                mym_status = mym();
                if(mym_status~=0) %0 when mym is open and reachable (connected)
                    mym('open','localhost',dbStruct.user,dbStruct.password);
                    mym(['USE ',dbStruct.name]);
                end
                
                for k=1:numel(event_settings)
                    event_settings{k}.detectorID = zeros(size(event_settings{k}.configID)); %allocate detectorIDs
                    for config=1:event_settings{k}.numConfigurations
                        event_k = event_settings{k};
                        event_k.configID = event_k.configID(config);
                        event_k.params = event_k.params(config);  %make a slim version for each config, useful for calling insertDatabaseDetectorInfoRecord...
                        Q = mym('SELECT DetectorID as detectorID FROM detectorinfo_t WHERE DetectorLabel="{S}" and configID={Si}',event_k.method_label,event_k.configID);
                        %if it doesn't exist at all
                        event_k.detectorID = Q.detectorID; %this is correct - it should be empty if it doesn't exist.
                        
                        if(~isempty(Q.detectorID))
                            mym(sprintf('DELETE FROM %s WHERE detectorID=%d',dbStruct.table,event_k.detectorID));
                            
                            %replace the configParamStruct in the chance that
                            %there is a difference between the existing one and
                            %the new one being added in the future.
                            %                             mym('update DetectorInfo_T set ConfigChannelLabels="{M}", ConfigParamStruct="{M}" WHERE DetectorID={Si}',event_k.channel_labels,event_k.params,event_k.detectorID);
                        else
                            %I need to add/insert the detector config to detectorinfo_t here...
                            %add it either way okay...
                            CLASS_database.insertDatabaseDetectorInfoRecord(dbStruct,event_k)
                        end
                        
                        %now get the detectorID that I have for these...
                        Q = mym('SELECT DetectorID as detectorID FROM detectorinfo_t WHERE DetectorLabel="{S}" and configID={S0}',event_k.method_label,event_k.configID);
                        event_settings{k}.detectorID(config) = Q.detectorID; %this is correct - it should be empty if it doesn't exist.
                    end
                end
                if(mym_status~=0)
                    mym('close');
                end
                
            end
        end
        
        % ======================================================================
        %> @brief Writes information in mym query output q to a file.
        %> @param q The mym query result to be written to file
        %> @param filename Name of the file to store data to (will be
        %> created if it does not already exist, or overwrite existing
        %> contents
        %> @param optional_delim Optional string delimiter to separate output fields
        %> The default is tab delimited (i.e. '\t')
        %> @note set optional_delim to ',' for comma separated values.
        function query2file(q,filename,optional_delim)
            fid = fopen(filename,'w');
            if(nargin<=2)
                fprintf(fid,'%s',CLASS_database.query2text(q));                
            else
                fprintf(fid,'%s',CLASS_database.query2text(q,optional_delim));
            end
            fclose(fid);
        end
        
        
        % ======================================================================
        %> @brief Outputs mym query output statment to the console or string output.
        %> @param q The mym query result to be displayed
        %> @param optional_delim Optional string delimiter to separate output fields
        %> The default is tab delimited (i.e. '\t')
        %> @note set optional_delim to ',' for comma separated values.
        %> @retval strout Stores the output string when provided.
        function strout = query2text(q,optional_delim)
            if(nargin<2)
                delim='\t';
            else
                delim =optional_delim;
            end
            fields = fieldnames(q);
            numfields = numel(fields);
            numrecs = numel(q.(fields{1}));
            strout = sprintf(fields{1});
            for f=2:numfields
                strout = sprintf(strcat('%s',delim,'%s'),strout,fields{f});
            end
            
            for n=1:numrecs
                if(iscell(q.(fields{1})))
                    strout = sprintf('%s\n%s',strout,q.(fields{1}){n});
                else
                    strout = sprintf('%s\n%0.2f',strout,q.(fields{1})(n));
                end
                for f=2:numfields
                    if(iscell(q.(fields{f})))
                        if(numel(q.(fields{f}){n}==1))
                            strout = sprintf(strcat('%s',delim,'%c'),strout,q.(fields{f}){n});
                        else
                            strout = sprintf(strcat('%s',delim,'%s'),strout,q.(fields{f}){n});
                        end
                    else
                        strout = sprintf(strcat('%s',delim,'%0.2f'),strout,q.(fields{f})(n));
                    end
                end
            end
            if(nargout==0)
                fprintf(strout);                
            end
                

            
        end
        % ======================================================================
        %> @brief Insert a record into the detectorInfo_T table using the field/values passed in
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        %> @param detectStruct (detectorStruct) must have these fields:
        %> @li @c channel_labels: {'C3-M2'}
        %> @li @c method_function: 'detection_artifact_hp_20hz
        %> @li @c method_label: 'artifact_hp_20hz
        %> @li @c params: [1x1 struct]
        %> @li @c configID: 1
        %> @li @c detectorID: 1 or []            
        function insertDatabaseDetectorInfoRecord(dbStruct,detectStruct)
            
            %detectorinfo_t table create string:
            %             createStr = ['CREATE TABLE IF NOT EXISTS ',TableName,...
            %                 ' (DetectorId TINYINT(3) UNSIGNED NOT NULL AUTO_INCREMENT,',...
            %                 'DetectorFilename VARCHAR(50),',...
            %                 'DetectorLabel VARCHAR(50),',...
            %                 'ConfigID TINYINT(3) UNSIGNED DEFAULT 0,',...
            %                 'ConfigChannelLabels BLOB,',...
            %                 'ConfigParamStruct BLOB,',...
            %                 'PRIMARY KEY(DETECTORID))'];
            mym_status = mym();
            if(mym_status~=0) %0 when mym is open and reachable (connected)
                CLASS_database.openDB(dbStruct);
            end
            
            detectorID = num2str(detectStruct.detectorID);
            if(isempty(detectorID))
                detectorID = 'NULL';
            end
            
            valuesStr = sprintf('%s,"%s","%s",%u',detectorID,detectStruct.method_function,detectStruct.method_label,detectStruct.configID);
            if(~isfield(detectStruct,'channel_configs'))
                channel_configs = detectStruct.channel_labels;
            else
                channel_configs = detectStruct.channel_configs;
            end
            if(isempty(channel_configs))
                channel_configs = detectStruct.channel_labels;
            else
                for k=1:numel(channel_configs)
                    if(isempty(channel_configs{k}))
                        channel_configs{k} = detectStruct.channel_labels{k};
                    end
                end
            end
            on_duplicate = sprintf(' on duplicate key update detectorfilename="%s", detectorlabel="%s", configchannellabels="{M}", configparamstruct="{M}"',detectStruct.method_function,detectStruct.method_label);
            try
                mym(['insert into detectorinfo_t values (',valuesStr,',"{M}","{M}")', on_duplicate],channel_configs,detectStruct.params,channel_configs,detectStruct.params);
            catch me
                showME(me);
            end
            if(mym_status~=0)
                mym('close');
            end
            
        end
        
        
        % ======================================================================
        %> @brief Retrieves database access data as a struct from
        %> the .inf filename provided.
        %> @param inf_filename Full filename (i.e. path included) of text
        %> file containing database accessor information 'name', 'user', 'password' as tab-delimited entries.
        %> @param optional_choice Optional index that can be provided to return the specified database
        %> preference when multiple database entries are present in the supplied inf_filename (integer)
        %> @retval database_struct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        function database_struct = loadDatabaseStructFromInf(inf_filename,optional_choice)
            %Hyatt Moore, IV (< June, 2013)

            database_struct = [];
            if(exist(inf_filename,'file'))
                fid = fopen(inf_filename,'r');
                database_cell = textscan(fid,'%s %s %s','commentstyle','#');
                fclose(fid);
                if(~isempty(database_cell))
                    if(nargin>1 && ~isempty(optional_choice))
                        database_struct.name = database_cell{1}{optional_choice};
                        database_struct.user = database_cell{2}{optional_choice};
                        database_struct.password = database_cell{3}{optional_choice};
                    else
                        database_struct.name = database_cell{1};
                        database_struct.user = database_cell{2};
                        database_struct.password = database_cell{3};
                    end
                end
            end
        end
        
        %> @brief Calculates cycle vector from .STA files and creates a .STA2 file 
        %> (i.e. a new file with a .STA2 extension) which has a third column for the stage cycle:
        %> [column 1: epoch column] [2: stage column] [3: stage cycle]
        %> @param STA_pathname Optional directory name (string) containing the .STA
        %> files to process.  User is prompted for directory name if one
        %> is not provided.
        %> @param patID_studyNum_regexp Regular expression (string) for
        %> how to identify the <i>PatID</i> and <i>StudyNum</i> fields from the .STA
        %> filenames.
        function makeSTA2file(STA_pathname,patID_studyNum_regexp)
            save2file = true;
            CLASS_database.stage2stats(STA_pathname,patID_studyNum_regexp,save2file);
        end
            
        %> @brief Converts .STA files (ascii tab delimited files with first column epoch
        %> number and second column the corresponding sleep stage) to a three column
        %> .STA file - the third column being the cycle of the current stage (e.g.
        %> many rem cycles, 1st, 2nd, third, etc.  Also calculates statistics:
        %> pct of rem, nrem, stage 1,2,3,4,5,0,7 and returns as a
        %> structure.
        %> @param STA_pathname Optional directory name (string) containing the .STA
        %> files to process.  User is prompted for directory name if one
        %> is not provided.
        %> @param patID_studyNum_regexp Regular expression (string) for
        %> how to identify the <i>PatID</i> and <i>StudyNum</i> fields from the .STA
        %> filenames.
        %> @param save2file Optional boolean value which, if true, results
        %> in creation of a .STA2 file that adds a third column for the the
        %> stage cycle.  See CLASS_database method makeSTA2file.
        %> @retval stats A cell of stage structures        
        function stats = stage2stats(STA_pathname,patID_studyNum_regexp,save2file) %,databasename, user, password)
            
            %
            % Written by Hyatt Moore
            % Modified 12.3.2012 - add cycle field to distinguish current NREM/REM
            % cycle
            % Modified 10.25.2012
            % altered to handle the case of different patid studynum combinations for
            % file formats; will help with PTSD, and SSC file name conventions which
            % are different than WSC's.
            
            if(nargin<1)
                STA_pathname = uigetdir(pwd,'Select stage (.STA) directory');
            end
            
            if(~isempty(STA_pathname))
                if(~ispc)
                    dirStruct = [dir(fullfile(STA_pathname,'*.STA'));dir(fullfile(STA_pathname,'*.sta'))];
                else
                    dirStruct = dir(fullfile(STA_pathname,'*.STA'));
                end
                
                if(~isempty(dirStruct))
                    filecount = numel(dirStruct);
                    filenames = cell(numel(dirStruct),1);
                    [filenames{:}] = dirStruct.name;
                end
                %example filename:    A0097_4 174733.STA
                if(nargin<2)
                    exp = '(?<PatID>[a-zA-Z0-9]+)_(?<StudyNum>\d+)[^\.]+\.STA';
                else
                    exp = patID_studyNum_regexp;
                end
                
                fCell= regexp(filenames,exp,'names');
                
                stats = cell(filecount,1);
                
                for k=1:filecount
                    %    tic
                    if(~isempty(fCell{k})) % && ~strcmp(fCell{k}.method,'txt')) %SECOND PART is no longer necessary
                        try
                            sta_filename = fullfile(STA_pathname,filenames{k});

                            STAGES = loadSTAGES(sta_filename);
                            cycle_vector = CLASS_database.stage2cycle(STAGES.line);
                            stage_stats = CLASS_database.getStagingStats(STAGES.line,cycle_vector,STAGES.cycles,fCell{k}.PatID,fCell{k}.StudyNum);
                            
                            stats{k} = stage_stats;
                            
                            if(nargin>=3 && save2file)
                                
                                stage_vector = STAGES.line;
                                stage_vector(isnan(stage_vector))=7; %reset these to be number 7

                                epoch_vector = 1:numel(stage_vector);
                                cycle_vector = stage2cycle(stage_vector(:,2));
                                
                                staging_matrix = [epoch_vector(:),stage_vector(:),cycle_vector(:)]; %just make it a three column section
                                save(fullfile(STA_pathname,[filenames{k},'2']),'staging_matrix','-ascii');
                            end
                           
                        catch me
                            showME(me);
                            stats{k} = [];
                        end
                    else
                        fprintf(1,'%s is missing\n',filenames{k});
                        stats{k} = [];
                    end
                end
                
            end
            
            
        end
        
        % ======================================================================
        %> @brief Calculates statistics of scored sleep stages.
        %> @param stage_vector Numeric vector of consecutively scored sleep stages.
        %> @param sleepfragmentation_vector Vector of length(stage_vector) with
        %> elements containing the cycle of the stage at the corresponding
        %> position in stage_vector.  See CLASS_database method <i>stage2cycle</i>
        %> @param nrem_rem_cycle_vector
        %> @param PatID
        %> @param StudyNum
        %> @retval staging_stats Structure (struct) with staging
        %> statisitcs.  It includes the following fields:
        %> @li PatID
        %> @li StudyNum Foreign key reference
        %> @li Stage The numeric stage {e.g. REM,NREM,Wake, SWS, etc}
        %> @li Cycle The NREM/REM sleep cycle (1,2,3,etc.)
        %> @li Duration Calculated as 30-second/epoch*stage.count;
        %> @li Count Number of epochs labeled with stage.ID
        %> @li Pct_study
        %> @li Pct_sleep
        %> @li Fragmentation_count Number of times the sleep stage was switched from
        %> @li Latency The duration in seconds from first non-wake period
        %> @note This method is a helper for CLASS_database method stage2stats
        function staging_stats = getStagingStats(stage_vector,sleepfragmentation_vector,nrem_rem_cycle_vector,PatID,StudyNum)
            %stage_vector is a 1xN vector that contains staging data corresponding to
            %ordinal epochs.
            %cycle_vector is a 1xN vector of the cycle of the stage at the same
            %position in stage_vector
            %for example if stage_vector is [1 1 5 5 1 1 2 2 5 5]
            %then cycle_vector is [1 1 1 1 2 2 1 1 2 2]
            
            epoch_dur_sec = 30; %30 second epochs
            uniqueStages = unique(stage_vector);
            uniqueCycles = unique(nrem_rem_cycle_vector);
            stage.PatID = PatID;
            stage.StudyNum=StudyNum; %foreign key reference
            stage.Stage=zeros(size(uniqueCycles)); %REM,NREM,Wake, SWS, etc
            stage.Cycle = zeros(size(uniqueCycles)); %NREM/REM sleep cycle (1,2,3,etc.)
            stage.Duration = zeros(size(uniqueCycles)); %30-second/epoch*stage.count;
            stage.Count = zeros(size(uniqueCycles)); %number of epochs labeled with stage.ID
            stage.Pct_study = zeros(size(uniqueCycles));
            stage.Pct_sleep = zeros(size(uniqueCycles));
            stage.Fragmentation_count = zeros(size(uniqueCycles)); %number of times the sleep stage was switched from
            stage.Latency = zeros(size(uniqueCycles)); %latency -> duration in seconds from first non-wake period
            %rem latency -> duration in seconds from first non-wake period to rem.
            
            stage = repmat(stage,numel(uniqueStages),1);
            
            total_study_sec = sum(stage_vector~=7)*epoch_dur_sec;
            total_sleep_sec = sum(stage_vector~=7&stage_vector~=0)*epoch_dur_sec;
            
            first_non_wake_vec = stage_vector~=0&stage_vector~=7;
            first_non_wake_ind = find(first_non_wake_vec==1,1); %if this is empty, then we have problems and need to reject anyway
            if(isempty(first_non_wake_ind))
                disp([PatID,StudyNum,' stage file does not contain any valid sleep stages!']);
                stage = [];
            else
                
                for k=1:numel(uniqueStages)
                    curStage = uniqueStages(k);
                    for c = 1:numel(uniqueCycles)
                        curCycle = uniqueCycles(c);
                        matching_stage_cycle = (stage_vector == curStage) & (nrem_rem_cycle_vector==curCycle);
                        stage(k).Cycle(c) = curCycle;
                        stage(k).Stage(c)=curStage;
                        
                        stage(k).Count(c) = sum(matching_stage_cycle);
                        if(stage(k).Count(c)>0)
                            stage(k).Duration(c) = stage(k).Count(c)*epoch_dur_sec;
                            stage(k).Pct_study(c) = stage(k).Duration(c)/total_study_sec;
                            stage(k).Pct_sleep(c) = stage(k).Duration(c)/total_sleep_sec;
                            frag_vec = sleepfragmentation_vector(matching_stage_cycle);   %find(stage_vector==curStage,1,'last')); %get the last/maximum cycle value
                            stage(k).Fragmentation_count(c) = frag_vec(end)-frag_vec(1);
                            stage(k).Latency(c) = (find(matching_stage_cycle,1)-first_non_wake_ind)*epoch_dur_sec; %this will be negative for some ... %a value of 0 means it is the first to occur
                        end
                    end
                end
                
            end
            staging_stats = stage;
        end
        
        % ======================================================================
        %> @brief Determines the cycle of score sleep stages by grouping
        %> consecutive periods of the same numeric sleep stage into cycles of
        %> that stage.
        %> @note stage_vector is a 1xN vector that contains staging data corresponding to
        %> ordinal epochs.
        %> cycle_vector is a 1xN vector of the cycle of the stage at the same
        %> position in stage_vector
        %> for example if stage_vector is [1 1 5 5 1 1 2 2 5 5]
        %> then cycle_vector is [1 1 1 1 2 2 1 1 2 2]
        %> @param stage_vector Numeric vector of consecutively scored sleep stages.
        %> @retval cycle_vector Vector of length(stage_vector) with
        %> elements containing the cycle of the stage at the corresponding
        %> position in stage_vector.
        function cycle_vector =  stage2cycle(stage_vector)
            
            %capture the vector of cycle changes; %non-zeros from the diff occur at the
            %last element before a transition - it represents where a cycle ends before
            %another begins
            cycle_changes = find(diff(stage_vector)~=0);
            
            %adding a one to the cycle_change represents where the next consecutive
            %cycle begins
            cycle_range = [[1;cycle_changes(:)+1],[cycle_changes(:);numel(stage_vector)]];
            
            cycle_vector = zeros(size(stage_vector));
            stages = zeros(max(stage_vector(:))+1,1);
            
            for k=1:size(cycle_range,1)
                cur_stage = stage_vector(cycle_range(k,1)); %cycle_range(k,1) is the index of stage_vector where a cycle of the same stage begins; cycle_range(k,2) is the index of where that cycle ends in stage_vector
                stages(cur_stage+1)=stages(cur_stage+1)+1; %(cur_stage+1) b/c Matlab is 1-based;
                cycle_vector(cycle_range(k,1):cycle_range(k,2)) = stages(cur_stage+1);
            end
            
        end
        
                % ======================================================================
        %> @brief Populates DetectorInfo_T table with manually scored event labels obtained from
        %> WSC .SCO files
        %> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        % =================================================================
        function populate_SCO_DetectorInfo_T(dbStruct)
            %need to add the SCO table information as it is not in the detection.inf
            %file since it is not incorporated into the SEV
            %a detection.inf line would look like this for a .SCO method
            %none SCO_Central_Apnea 0 none SCO_Central_Apnea
            
            %add SEV to the path
            
            % #Matlab_filename   Label Number_of_channels_required Dialog_name Batch_mode_score
            SCO_labels = {'SCO_Central_Apnea'
                'SCO_Hypopnea'
                'SCO_LM'
                'SCO_LMA'
                'SCO_PLM'
                'SCO_Mixed_Apnea'
                'SCO_Obs_Apnea'
                'SCO_SaO2'
                'SCO_Arousal'
                'SCO_RESPIRATORY_EVENT'
                'SCO_Desat'};
            detectStruct.channel_labels ={'LAT/RAT'};
            
            detectStruct.configID = 1;
            detectStruct.detectorID = [];
            detectStruct.method_function = [];
            detectStruct.method_label = [];
            detectStruct.params = [];
            
            for k=1:numel(SCO_labels)
                detectStruct.method_function = SCO_labels{k};
                detectStruct.method_label = SCO_labels{k};
                CLASS_database.insertDatabaseDetectorInfoRecord(dbStruct,detectStruct);
            end
        end
        
        
            
        % @brief Export parts of WSC Diagnostics_T to tab delimited text
        % file
        % @param txt_filname Name of the file to write data to (it will be
        % created or over written depending if it already exists or not).
        function diagnostics2txt(txt_filename)
            % Author: Hyatt Moore IV
            % created 8/28/12
            % modified 11/13/12
            % modified 2/11/13 - updated for Eileen transfer
            % modified 2/11/13 - updated for Eileen and Emmanuel transfer
            %modified 2/13/13 - updated to handle the genetic polymorphisms
            % modified 2/27/13 - update for Emmanuel and Eileen for later
            %  txt_filename = fullfile(pwd,'diagnostics_for_Laurel.txt');
            
            CLASS_WSC_database.open();
            fid = fopen(txt_filename,'w');
            
            
            q=mym('select concat(studyinfo_t.patid,"_",studyinfo_t.studynum) as PatID_StudyNum, detectorid,withwake, RLS_A, RLS_B, (RLS_A=1 or rls_b=1) as RLS_AB, RLS_C, AHI4>=15 as has_OSA,plmi,plm_count,lmcount,periodicity,plm_to_lm_ratio,ratio_plm,ratio_lm  from studyinfo_t join plm_t using (patstudykey) left join diagnostics_t using (patstudykey) where detectorid in (142,143) order by detectorid, withwake, patstudykey');
            
            mym('CLOSE');            
            
            fields = fieldnames(q);
            for f=1:numel(fields)
                fprintf(fid,'%s\t',fields{f});
            end
            for p=1:numel(q.PatID_StudyNum)
                fprintf(fid,'\n');
                for f=1:numel(fields)
                    if(iscell(q.(fields{f})))
                        fprintf(fid,'%s\t',q.(fields{f}){p});
                    else
                        if(isnan(q.(fields{f})(p)))
                            fprintf(fid,'\t');
                        else
                            fprintf(fid,'%0.2f\t',q.(fields{f})(p));
                        end
                    end
                end
            end
            
            fclose(fid);
        end
        
        function exportQuery2File(query, filename, optional_delim)
            if(isstruct(query))
                q = query;
            else
                q = mym(query);
            end
            fields = fieldnames(q);
            fid = fopen(filename,'w');
            
            if(fid<=0)
                fprintf('File could not be opened for writing!');
            else
                if(nargin<3)
                    delim='\t';
                else
                    delim =optional_delim;
                end
                for f=1:numel(fields)
                    fprintf(fid,strcat('%s',delim),fields{f});
                end
                
                
                for p=1:numel(q.patstudykey)
                    fprintf(fid,'\n');
                    for f=1:numel(fields)
                        if(iscell(q.(fields{f})))
                            fprintf(fid,strcat('%s',delim),q.(fields{f}){p});
                        else
                            if(isnan(q.(fields{f})(p)))
                                fprintf(fid,delim);
                            else
                                fprintf(fid,strcat('%0.2f',delim),q.(fields{f})(p));
                            end
                        end
                    end
                end
                fclose(fid);
            end            
        end
    end
    
end

