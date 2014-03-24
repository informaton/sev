%> @file CLASS_CManager_database.m
%> @brief Cohort database development class for managing and organizing data from 
%> various sleep cohorts.
% ======================================================================
%> @brief The class is designed for database development, functionality, and 
%> interaction with SEV and the various cohort database it interacts with
%> @note: A MySQL database must be installed on the local host for class
%> instantiations to operate correctly.
% ======================================================================
classdef CLASS_CManager_database < CLASS_database

    properties (Constant)
        dbName = 'CManager_DB';
        dbUser = 'CManager_user';
        dbPassword = 'CManager_password';
        fileTypes = {'edf','stage','sco','xml','events'};        
    end
    
    methods
        function obj = CLASS_CManager_database()
            obj.dbStruct = CLASS_CManager_database.getDBStruct();
        end
        
        %this must be defined as it is an abstract method...
        function create_Diagnostics_T(~)
            
        end
        
        function makeAll(obj)
            obj.createDBandTables();
            obj.updateDBandTables();
        end
        
        function createDBandTables(obj)
            obj.create_DB();
            obj.create_FileStudyInfo_T();
            obj.create_CohortInfo_T();
            obj.create_DatabaseInfo_T();            
        end
        
        function updateDBandTables(obj)
           obj.update_CohortInfo_T();
           obj.update_FileStudyInfo_T();
           obj.update_DatabaseInfo_T();           
        end        
        
        function update_FileStudyInfo_T(obj) 
           %obtain updates based on the cohort information that i have.
           %Note: A file is not updated until it has been assigned to a
           %cohort as entered in the update_CohortInfo_T call.
           obj.open();
           TableName = lower('FileStudyInfo_T');           
           cohort_q= mym('select * from cohortinfo_t');           
           summary = '';
           for c = 1:numel(cohort_q.cohortID)
               cohortID = cohort_q.cohortID(c);
               database_q = mym('select dbid from databaseinfo_t where name="{S}_DB"',cohort_q.name{c});
               databaseID = database_q.dbid;
               
               folder_found = false;
               files_found = false;
               
               %This is an APOE example, where the EDF's and files are all
               %subfolders of the root foldername
               
               if(exist(cohort_q.root_foldername{c},'dir'))                   
                   folder_found = true;
                   folderNames = getPathnames(cohort_q.root_foldername{c});
                   if(~iscell(folderNames))
                       folderNames = {folderNames};
                   end                   
                   for f=1:numel(folderNames)
                       curStudy = [];
                       curStudy.cohortID =cohortID;
                       curStudy.dbID = databaseID;
                       curStudy.datetimefirstadded = 'now()';
                       
                       cur_folder = fullfile(cohort_q.root_foldername{c},folderNames{f});
                       curStudy.sub_foldername = folderNames{f};
                       [curStudy, files_found] = CLASS_CManager_database.updateCohortStudyStruct(curStudy,'all', cur_folder);
                       if(files_found)
                           try
                               CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy)
                           catch me
                               showME(me);
                               fprintf('Failsed on %s\n',cur_folder);
                           end
                       else
                           fprintf('No files found in %s!\n',cur_folder);
                       end

                   end  
                   
               %This is a WSC example, where the EDF's and files are all
               %located in the all foldername

               elseif(exist(cohort_q.all_foldername{c},'dir'))
                   folder_found = true;
                   %in this case just, set the cur folder
                   cur_folder = cohort_q.all_foldername{c};
                   
                   edf_filenames = strrep(getFilenames(cur_folder,'*.edf'),'.edf','');
                   EDF_filenames = strrep(getFilenames(cur_folder,'*.EDF'),'.EDF','');
                   sta_filenames = strrep(getFilenames(cur_folder,'*.sta'),'.sta','');
                   STA_filenames = strrep(getFilenames(cur_folder,'*.STA'),'.STA','');
                   
                   unique_names = unique([edf_filenames(:);EDF_filenames(:);sta_filenames(:);STA_filenames(:)]);
                   
                   for u=1:numel(unique_names)
                       curStudy = [];
                       curStudy.cohortID =cohortID;
                       curStudy.dbID = databaseID;
                       curStudy.datetimefirstadded = 'now()';
                       cur_name = unique_names{u};
                       [curStudy, files_found] = CLASS_CManager_database.updateCohortStudyStruct(curStudy,'all', cur_folder,cur_name);                       
                       if(files_found)
                           try
                               CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy)
                           catch me
                               showME(me);
                               fprintf('Failed on %s\n',cur_folder);
                           end
                       else
                           fprintf('No files found for %s: %s!\n',cur_folder,cur_name);
                       end

                   end
               else
                   %go through the list of possible extensions
                   edf_names = {};
                   sta_names = {};
                   
                   if(exist(cohort_q.edf_foldername{c},'dir'))
                       cur_folder = cohort_q.edf_foldername{c};
                       folder_found = true;
                       edf_filenames = strrep(getFilenames(cur_folder,'*.edf'),'.edf','');
                       EDF_filenames = strrep(getFilenames(cur_folder,'*.EDF'),'.EDF','');
                       edf_names = unique([edf_filenames(:);EDF_filenames(:)]);
                   end                   
                   if(exist(cohort_q.stage_foldername{c},'dir'))
                       folder_found = true;
                       cur_folder = cohort_q.stage_foldername{c};
                       sta_filenames = strrep(getFilenames(cur_folder,'*.sta'),'.sta','');
                       STA_filenames = strrep(getFilenames(cur_folder,'*.STA'),'.STA','');
                       sta_names = unique([sta_filenames(:);STA_filenames(:)]);
                   end
                   unique_names = unique([edf_names(:); sta_names(:)]);
                   for u=1:numel(unique_names)
                       
                       cur_name = unique_names{u};
                       curStudy.cohortID =cohortID;
                       curStudy.dbID = databaseID;
                       curStudy.datetimefirstadded = 'now()';
                       
                       for f=1:numel(CLASS_CManager_database.fileTypes)
                           curExt = CLASS_CManager_database.fileTypes{f};
                           fname = strcat(curExt,'_foldername');
                           cur_folder = cohort_q.(fname){c};
                           if(exist(cur_folder,'dir'))
                               folder_found = true;
                               [curStudy, local_files_found] = CLASS_CManager_database.updateCohortStudyStruct(curStudy,curExt, cur_folder,cur_name);
                               files_found = files_found || local_files_found;
                           end
                       end
                       
                       if(files_found)
                           try                       
                               CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy)
                               
                           catch me
                               showME(me);
                               fprintf('Failed on %s\n',cur_name);
                           end
                       else
                           fprintf('No files found for %s!\n',cur_name);
                       end
                   end
               end                   
               if(~folder_found)
                   fprintf('No source folders found for %s!\n',cohort_q.name{c});
               end
           end
        end
        
        function update_CohortInfo_T(obj,filename)
            TableName = lower('CohortInfo_T');
            
            %get this from my sev file
            if(nargin<2)
                filename = uigetfullfile({'*.str','Cohort structure file (*.str)'},'Select cohort information structure file');
            end
            if(exist(filename,'file'))
                obj.open();
                cohortStruct = obj.loadCohortStruct(filename);
                if(~isempty(cohortStruct))
                    cohorts = fieldnames(cohortStruct);
                    for f=1:numel(cohorts)
                        curCohort = cohortStruct.(cohorts{f});
                        if(isfield(curCohort,'name'))
                            names = ' (';
                            values = '(';
                            curFields = fieldnames(curCohort);
                            for cf=1:numel(curFields)
                                curField = curFields{cf};
                                curValue = strrep(curCohort.(curField),'"','\"');
                                names = sprintf('%s %s,',names,curField);
                                values = sprintf('%s "%s",',values,curValue);
                            end
                            names(end)=')';
                            values(end)=')';
                            
                            insertStr = ['INSERT IGNORE INTO ',TableName,names,' VALUES ',values];
                            try
                                mym(insertStr);
                            catch me
                                showME(me);
                            end
                        end
                    end
                    obj.close();
                end
            end         
        end

        % Studyinfo Table fields:
        % 1 UID - universal ID (primary, foreign key, can be empty?)
        % 2 DBid - Database Info's primary key (primary, foreign key; default is 0 which means the study is not in a database).
        % 3 Patstudykey - the primary key of this record in the associated database; there is a problem with how to identify these if they are not in a database.  I see two solutions: (1.)  Build the indexing database first and then build the suboordinate, cohort databases next with the requirement that they use the same patstudykey values for their own entries.  (2.)  Leave the patstudykey blank and instead use the filename and cohort name, combined, as the primary key.
        % 4 Filename - name of the .edf (e.g. R0017_2 080612.EDF)
        % 5 Date/time Added (e.g. 2014-01-27, 16:49)
        % 6 Stage file exists (yes/no - or use empty stage filename)
        % 7 event file exists (yes/no - or use empty event filename)
        % 8 Stage file name (empty for none)
        % 9 event file name (empty for none)
        function create_FileStudyInfo_T(obj) 
            obj.open();            
            TableName = 'filestudyInfo_T';
            TableName = lower(TableName);
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'(',...
                '  uID INT UNSIGNED DEFAULT NULL ',...
                ', cohortID SMALLINT UNSIGNED NOT NULL',...
                ', dbID SMALLINT UNSIGNED DEFAULT NULL',...
                ', fileID INT UNSIGNED NOT NULL AUTO_INCREMENT',...
                ', patstudykey SMALLINT UNSIGNED DEFAULT NULL',...
                ', datetimelastupdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',...
                ', datetimefirstadded TIMESTAMP NOT NULL',...
                ', patid varchar(30) DEFAULT NULL',...
                ', sub_foldername VARCHAR(70) NULL',...
                ', has_edf_file BOOL DEFAULT FALSE',...
                ', edf_filename VARCHAR(70) DEFAULT NULL',...
                ', has_sta_file BOOL DEFAULT FALSE',...
                ', sta_filename VARCHAR(70) DEFAULT NULL',...
                ', has_evt_file BOOL DEFAULT FALSE',...
                ', evt_filename VARCHAR(70) DEFAULT NULL',...
                ', has_sco_file BOOL DEFAULT FALSE',...
                ', sco_filename VARCHAR(70) DEFAULT NULL',...
                ', has_xml_file BOOL DEFAULT FALSE',...
                ', xml_filename VARCHAR(70) DEFAULT NULL',...                
                ', PRIMARY KEY (fileID)',...                
                ')']);
            obj.close();
        end
        
        function create_CohortInfo_T(obj)
            obj.open();
            TableName = 'cohortInfo_T';
            TableName = lower(TableName);
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'(',...
                ' cohortID SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT',...
                ', name VARCHAR(30) NOT NULL DEFAULT "whoRwe"',...
                ', projectname VARCHAR(30) DEFAULT NULL',...                
                ', location VARCHAR(30) DEFAULT "somewhere"',...                
                ', root_foldername varchar(128) DEFAULT NULL',...
                ', all_foldername varchar(128) DEFAULT NULL',...
                ', edf_foldername varchar(128) DEFAULT NULL',...
                ', stage_foldername varchar(128) DEFAULT NULL',...
                ', events_foldername varchar(128) DEFAULT NULL',...
                ', xml_foldername varchar(128) DEFAULT NULL',...
                ', sco_foldername varchar(128) DEFAULT NULL',...   
                ', patient_description_file varchar(128) DEFAULT NULL',...                
                ', transformation_script VARCHAR(128) DEFAULT NULL',...
                ', Montage_suite ENUM(''Grass'',''Gamma'',''Twin'',''Embla Sandman'',''Woodward'',''Unknown'',''Various'') DEFAULT ''Unknown''',...
                ', pointofcontact VARCHAR(128) DEFAULT NULL',...
                ', notes VARCHAR(512) DEFAULT NULL',...
                ', reference VARCHAR(256) DEFAULT NULL',...
                ', website VARCHAR(128) DEFAULT NULL',...
                ', timeframe VARCHAR(128) DEFAULT NULL',...                
                ', PRIMARY KEY (cohortID)',...
                ', CONSTRAINT UNIQUE (name, projectname)',...                
                ')']);
            
            obj.close();
        end

        % Database Info Table fields
        % 1.  DBid - data base info's primary key (e.g. 0, 1, 2, etc)
        % 2.  Cohort name (e.g. WSC, SSC, SSC-APOE)
        % 3.  Montage type (e.g. grass, twin, sandman, unknown)
        % 4.  EDF/file pathname (e.g. /data1/SSC/APOE)
        % 5.  Transformation script (e.g. /data1/exportScripts/SSC_APOE_convert.m; alternatively, we could store the script itself as a field entry)
        % 6.  Point of Contact (e.g. Eileen Leary; Robin Stubbs; Oscar Carrillo)
        % 7.  Notes (e.g. The files are from China; Ling lin started the development work and is a good contact for following up with collaborator fang han)
        % 8.  Database accessor fields (Database name, user name, password)
        function create_DatabaseInfo_T(obj)
            obj.open();
            TableName = 'DatabaseInfo_T';
            TableName = lower(TableName);
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'(',...
                ' dbID SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT',...
                ', name varchar(20) not null',...
                ', user varchar(20) not null',...
                ', password varchar(20) not null',...
                ', creationScript varchar(70) default NULL',...
                ', PRIMARY KEY (dbID)',...
                ', CONSTRAINT UNIQUE (name, user, password) ',...
                ')']);
            
            obj.close();
        end
        
        function update_DatabaseInfo_T(obj, filename)
            TableName = lower('DatabaseInfo_T');
            
            %get this from my sev file
            if(nargin<2)
                filename = uigetfullfile({'*.inf','Database information file (*.inf)'},'Select SEV database cohort information file');
            end
            if(exist(filename,'file'))
                obj.open()
                database_struct = obj.loadDatabaseStructFromInf(filename);
                
                if(~isempty(database_struct) && isfield(database_struct,'name'))
                    num_entries = numel(database_struct.name);
                    preInsertStr = ['INSERT IGNORE INTO ',TableName, ' (name,user, password) VALUES ("%s", "%s", "%s")'];
                    for n=1:num_entries
                        try
                            mym(sprintf(preInsertStr,database_struct.name{n},database_struct.user{n},database_struct.password{n}));
                        catch me
                            showME(me);
                        end
                    end
                end
                obj.close();
            end
        end
    end
    
    methods(Static, Access=private)
        function dbStruct = getDBStruct()
            dbStruct.name = CLASS_CManager_database.dbName;
            dbStruct.user = CLASS_CManager_database.dbUser;
            dbStruct.password = CLASS_CManager_database.dbPassword;
        end
        
        function [cohortStudy, files_found] = updateCohortStudyStruct(cohortStudy,fileExtension, foldername,studyName)
            
            if(nargin<4 || isempty(studyName))
                studyName = '*';
            end
            files_found = false;
            if(strcmpi(fileExtension,'all'))                
                fileExtensions = CLASS_CManager_database.fileTypes;
                foldername = repmat({foldername},numel(fileExtensions),1);
            else
                if(~iscell(fileExtension))
                    fileExtensions = {fileExtension};
                    foldername = {foldername};
                end                
            end
            for f=1:numel(fileExtensions)
                cur_extension = fileExtensions{f};
                cur_folder = foldername{f};
                switch(cur_extension)
                    case 'edf'
                        edf_file = getFilenames(cur_folder,strcat(studyName,'.EDF'));
                        if(isempty(edf_file))
                            edf_file = getFilenames(cur_folder,strcat(studyName,'.edf'));
                        end
                        if(~isempty(edf_file))
                            cohortStudy.has_edf_file = true;
                            cohortStudy.edf_filename = edf_file{1};
                            files_found = true;
                        end
                    case 'stage'
                        sta_file = getFilenames(cur_folder,strcat(studyName,'.STA'));
                        if(isempty(sta_file))
                            sta_file = getFilenames(cur_folder,strcat(studyName,'.sta'));
                        end                        
                        if(~isempty(sta_file))
                            cohortStudy.has_sta_file = true;
                            cohortStudy.sta_filename = sta_file{1};
                            files_found = true;
                        end
                    case 'sco'                        
                        sco_file = getFilenames(cur_folder,strcat(studyName,'.SCO'));
                        if(isempty(sco_file))
                            sco_file = getFilenames(cur_folder,strcat(studyName,'.sco'));
                        end                        
                        if(~isempty(sco_file))
                            cohortStudy.has_sco_file = true;
                            cohortStudy.sco_filename = sco_file{1};
                            files_found = true;
                        end
                    case 'xml'
                        xml_file = getFilenames(cur_folder,strcat(studyName,'.XML'));
                        if(isempty(xml_file))
                            xml_file = getFilenames(cur_folder,strcat(studyName,'.xml'));
                        end
                        if(~isempty(xml_file))
                            cohortStudy.has_xml_file = true;
                            cohortStudy.xml_filename = xml_file{1};
                            files_found = true;
                        end
                    case 'events'
                        evt_file = getFilenames(cur_folder,strcat(studyName,'.evt'));
                        if(isempty(evt_file))
                            evt_file = getFilenames(cur_folder,strcat(studyName,'.evt'));
                        end
                        if(~isempty(evt_file))
                            cohortStudy.has_evt_file = true;
                            cohortStudy.evt_filename = evt_file{1};
                            files_found = true;
                        end
                    otherwise
                        fprintf('Unhandled case %s\n',cur_extension);
                end
            end
        end
        
        function insertRecordFromStruct(TableName,insertStruct)
            names = ' (';
            values = '(';
            curFields = fieldnames(insertStruct);
            for cf=1:numel(curFields)
                curField = curFields{cf};
                curValue = insertStruct.(curField);
                if(~isempty(curValue))
                    if(islogical(curValue))
                        values = sprintf('%s %u,',values,curValue);
                    elseif(ischar(curValue))
                        if(strcmpi(curField,'datetimefirstadded'))
                            values = sprintf('%s now(),',values);
                        else
                            curValue = strrep(insertStruct.(curField),'"','\"');
                            values = sprintf('%s "%s",',values,curValue);
                        end
                    elseif(isnumeric(curValue))
                        values = sprintf('%s %0.3g,',values,curValue);
                    end
                    names = sprintf('%s %s,',names,curField);
                end
            end
            names(end)=')';
            values(end)=')';
            insertStr = ['INSERT IGNORE INTO ',TableName,names,' VALUES ',values];
            try
                mym(insertStr);
            catch me
                showME(me);
            end
            
        end
    end
    
end