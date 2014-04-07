%> @file CLASS_CManager_database.m
%> @brief Cohort database development class for managing and organizing data from 
%> various sleep cohorts.
%> use makeAll() to create and update database and tables for first use.
%> use updateDBandTables() to subsequently update tables.
% ======================================================================
%> @brief The class is designed for database development, functionality, and 
%> interaction with SEV and the various cohort database it interacts with
%> @note A MySQL database must be installed on the local host for class
%> instantiations to operate correctly.
% ======================================================================
classdef CLASS_CManager_database < CLASS_database

    properties (Constant)
        dbName = 'CManager_DB';
        dbUser = 'CManager_user';
        dbPassword = 'CManager_password';
        fileTypes = {'psg','stage','sco','xml','events'};        
    end
    
    methods
        function obj = CLASS_CManager_database()
            obj.dbStruct = CLASS_CManager_database.getDBStruct();
        end
        
        %this must be defined as it is an abstract method...
        function create_Diagnostics_T(~)            
        end        
        
        %> @brief makeAll runs createDBandTables and updateDBandTables
        function makeAll(obj)
            obj.createDBandTables();
            obj.updateDBandTables();
        end
        
        %> @brief createDBandTables - creates the database and three tables
        %> - CohortInfo_T
        %> - DatabaseInfo_T
        %> - FileStudyinfo_T
        function createDBandTables(obj)
            obj.create_DB();
            obj.create_CohortInfo_T();
            obj.create_FileStudyInfo_T();  
            obj.create_DatabaseInfo_T();            
        end
        
        %> @brief updateDBandTables calls the update function for the three tables
        %> - CohortInfo_T
        %> - DatabaseInfo_T
        %> - FileStudyinfo_T
        %> @note Order of update (as listed above) is important as file
        %> studyinfo_t table uses cohortinfo_t entries to locate source files.
        function updateDBandTables(obj)
           obj.update_CohortInfo_T();
           obj.update_FileStudyInfo_T();
           obj.update_DatabaseInfo_T();           
        end
        
        %> @brief create_CohortInfo_T creates the cohortinfo_t table
        %> CohortInfo_T table fields include
        %> - cohortID Primary key with constraint that name and projectname
        %> are unique
        %> - name Name of the cohort (e.g. SSC)
        %> - projectname name of the specific project (e.g. APOE)
        %> - location Geographic location where sleep studies were
        %> performed.
        %> - src_foldername 
        %> - src_foldertype Either <b>tier</b> or <b>flat</b>
        %> - src_psg_foldername Folder name containing the original source
        %> (src) files for the cohort.
        %> - src_psg_extension filename extension of the psg (e.g. <b>.edf</b>)
        %> - src_stage_foldername stage foldername; used when folder type is <i>tier</i>
        %> - src_events_foldername events foldername; used when folder type is <i>tier</i>
        %> - src_xml_foldername xml foldername; used when folder type is <i>tier</i>
        %> - src_sco_foldername sco foldername; used when folder type is <i>tier</i>
        %> - working_foldername Folder name containing the files as
        %transfomred by *transformation_script*.  
        %> - working_foldertype Either <b>tier</b> or <b>flat</b>; default
        %> is <b>flat</b>
        %> - working_edf_foldername EDF foldername; used when folder type is <i>tier</i>
        %> - working_sta_foldername STA foldername; used when folder type is <i>tier</i>
        %> - working_sco_foldername SCO foldername; used when folder type is <i>tier</i>
        %> - patient_description_file
        %> - transformation_script Name of file used to transcode src files
        %> to working files.
        %> - src_mapping_file Name of file that contains the mapping from the src psg filenames to working filenames.
        %> - Montage_suite PSG montage used by cohort. enumerated ''Grass'',''Gamma'',''Twin'',''Embla Sandman'',''Woodward'',''Unknown'',''Various'') default is ''Unknown'''
        %> - pointofcontact Name and email of point of contact
        %> - notes Free form text.
        %> - reference Free form text
        %> - website Free form text
        %> - timeframe Free form text
        %> @note The fields should be listed in the cohort.str text file
        %> for updating; see @update_CohortInfo_T
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
                ', src_foldername varchar(128) DEFAULT NULL',...
                ', src_foldertype ENUM(''tier'',''flat'')',...
                ', src_psg_foldername varchar(128) DEFAULT NULL',...
                ', src_psg_extension varchar(4) DEFAULT ''.EDF''',...                
                ', src_stage_foldername varchar(128) DEFAULT NULL',...
                ', src_events_foldername varchar(128) DEFAULT NULL',...
                ', src_xml_foldername varchar(128) DEFAULT NULL',...
                ', src_sco_foldername varchar(128) DEFAULT NULL',...                   
                ', working_foldername varchar(128) DEFAULT NULL',...
                ', working_foldertype ENUM(''tier'',''flat'')',...
                ', working_edf_foldername varchar(128) DEFAULT NULL',...
                ', working_sta_foldername varchar(128) DEFAULT NULL',...
                ', working_sco_foldername varchar(128) DEFAULT NULL',...
                ', patient_description_file varchar(128) DEFAULT NULL',...                
                ', transformation_script VARCHAR(128) DEFAULT NULL',...
                ', src_mapping_file VARCHAR(128) DEFAULT NULL',...                
                ', Montage_suite ENUM(''Grass'',''Gamma'',''Twin'',''Embla Sandman'',''Woodward'',''Unknown'',''Various'') DEFAULT ''Unknown''',...
                ', pointofcontact VARCHAR(128) DEFAULT NULL',...
                ', notes VARCHAR(1024) DEFAULT NULL',...
                ', reference VARCHAR(512) DEFAULT NULL',...
                ', website VARCHAR(512) DEFAULT NULL',...
                ', timeframe VARCHAR(256) DEFAULT NULL',...                
                ', PRIMARY KEY (cohortID)',...
                ', CONSTRAINT UNIQUE (name, projectname)',...                
                ')']);
            obj.close();
        end
        
        %> @brief create_FileStudyInfo_T creates the filestudyinfo_t table.
        %> FileStudyinfo Table fields:        
        %> - uuid universal ID (primary, foreign key, can be empty?)
        %> - cohortID unique key of the cohort database each record is related to.
        %> - dbID Database Info's primary key (primary, foreign key; default is 0 which means the study is not in a database).
        %> - fileID primary key for each record
        %> - patstudykey the primary key of this record in the associated database; there is a problem with how to identify these if they are not in a database.  I see two solutions: (1.)  Build the indexing database first and then build the suboordinate, cohort databases next with the requirement that they use the same patstudykey values for their own entries.  (2.)  Leave the patstudykey blank and instead use the filename and cohort name, combined, as the primary key.
        %> - datetimelastupdated Date/time last updated. (e.g. 2014-01-27, 16:49)
        %> - datetimefirstadded Date/time Added (e.g. 2014-01-27, 16:49)
        %> - src_is_tiered 
        %> - src_sub_foldername 
        %> - src_has_psg_file Does it come with an .edf file
        %> - src_psg_filename name of the .edf (e.g. R0017_2 080612.EDF)
        %> - src_has_other_psg_file Does it come with a psg file that is
        %> not .edf
        %> - src_other_psg_filename name of the non .edf file (e.g. R0017_2 080612.SAN)
        %> - src_has_sta_file Has stage file? (yes/no - or use empty stage filename)
        %> - src_sta_filename Stage file name (empty for none)
        %> - src_has_evt_file event file exists (yes/no - or use empty event filename)
        %> - src_evt_filename event file name (empty for none)
        %> - src_has_sco_file 
        %> - src_sco_filename 
        %> - src_has_xml_file 
        %> - src_xml_filename 
        %> - working_is_tiered 
        %> - working_sub_foldername 
        %> - working_has_edf_file 
        %> - working_src_edf_filename
        %> - working_has_sta_file
        %> - working_sta_filename
        %> - working_has_sco_file
        %> - working_sco_filename
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
                ', src_is_tiered BOOL DEFAULT FALSE',...
                ', src_sub_foldername VARCHAR(70) NULL',...
                ', src_has_psg_file BOOL DEFAULT FALSE',...
                ', src_psg_filename VARCHAR(70) DEFAULT NULL',...
                ', src_has_sta_file BOOL DEFAULT FALSE',...
                ', src_sta_filename VARCHAR(70) DEFAULT NULL',...
                ', src_has_evt_file BOOL DEFAULT FALSE',...
                ', src_evt_filename VARCHAR(70) DEFAULT NULL',...
                ', src_has_sco_file BOOL DEFAULT FALSE',...
                ', src_sco_filename VARCHAR(70) DEFAULT NULL',...
                ', src_has_xml_file BOOL DEFAULT FALSE',...
                ', src_xml_filename VARCHAR(70) DEFAULT NULL',...                
                ', working_is_tiered BOOL DEFAULT FALSE',...
                ', working_sub_foldername VARCHAR(70) NULL',...
                ', working_has_edf_file BOOL DEFAULT FALSE',...
                ', working_src_edf_filename VARCHAR(70) DEFAULT NULL',...
                ', working_has_sta_file BOOL DEFAULT FALSE',...
                ', working_sta_filename VARCHAR(70) DEFAULT NULL',...
                ', working_has_sco_file BOOL DEFAULT FALSE',...
                ', working_sco_filename VARCHAR(70) DEFAULT NULL',...                
                ', PRIMARY KEY (fileID)',...                
                ')']);
            obj.close();
        end
        
        %> @brief create_DatabaseInfo_T create the database info table.
        %> Database Info Table fields include
        %> # 1.  DBid - data base info's primary key (e.g. 0, 1, 2, etc)
        %> # 2.  Cohort name (e.g. WSC, SSC,
        %> # 3.  Montage type (e.g. grass, twin, sandman, unknown)
        %> # 4.  EDF/file pathname (e.g. /data1/SSC/APOE)
        %> # 5.  Transformation script (e.g. /data1/exportScripts/SSC_APOE_convert.m; alternatively, we could store the script itself as a field entry)
        %> # 6.  Point of Contact (e.g. Eileen Leary; Robin Stubbs; Oscar Carrillo)
        %> # 7.  Notes (e.g. The files are from China; Ling lin started the development work and is a good contact for following up with collaborator fang han)
        %> # 8.  Database accessor fields (Database name, user name, password)
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
        
                
        %> @brief update_CohortInfo_T Updates the cohort table based on the
        %> input text file.
        %> @param filename Optional cohort structure file (*.str) which
        %> describes each cohort using tab delimited key value pairs.
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

        %> @brief obtain updates based on the cohort information avaialbe
        %> in the cohortinfo_t table.
        %> @note A file is not updated until it has been assigned to a
        %> cohort as entered in the update_CohortInfo_T call.
        function update_FileStudyInfo_T(obj)
           obj.open();
           TableName = lower('FileStudyInfo_T');
           cohort_q= mym('select * from cohortinfo_t');           
           for c = 1:numel(cohort_q.cohortID)
               cohortID = cohort_q.cohortID(c);
               database_q = mym('select dbid from databaseinfo_t where name="{S}_DB"',cohort_q.name{c});
               databaseID = database_q.dbid;
               src_foldertype = cohort_q.src_foldertype{c};
               src_foldername = cohort_q.src_foldername{c};
               
               working_foldertype = cohort_q.working_foldertype{c};
               working_foldername = cohort_q.working_foldername{c};
               src_mapping_file = cohort_q.src_mapping_file{c};
               psg_ext = cohort_q.src_psg_extension{c};
               
               
               
               %now look through the working folders...
               if(~exist(working_foldername,'dir'))
                   fprintf('Where did you go?\n');
                   fprintf('Could not find the working folder for PSGs (%s)!\n',working_foldername);
                   fprintf('No source folders found for %s!\n',cohort_q.name{c});
               else
                   
                   if(strcmpi(working_foldertype,'flat') && exist(src_mapping_file,'file'))
                       [mappingStruct, look4WorkFiles] = CLASS_CManager_database.loadMappingFile(src_mapping_file);
                   else                       
                       fprintf('This mode has not yet been accounted for (%s).\n',working_foldertype);
                       look4WorkFiles = false;               
                   end
               
                   %Is a tier folder structure used (e.g. an APOE example, where the EDF's and files are all
                   %subfolders of the root foldername)
                   % note: the subolder names must be the same as the .edf file
                   % names.
                   if(strcmpi(src_foldertype,'tier'))
                       
                       folderNames = getPathnames(src_foldername);
                       if(~iscell(folderNames))
                           folderNames = {folderNames};
                       end
                       
                       for f=1:numel(folderNames)
                           curStudy = [];
                           curStudy.cohortID =cohortID;
                           curStudy.dbID = databaseID;
                           curStudy.datetimefirstadded = 'now()';
                           
                           cur_folder = fullfile(src_foldername,folderNames{f});
                           curStudy.src_sub_foldername = folderNames{f};
                           
                           [curStudy, files_found] = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,'all', cur_folder,psg_ext);
                           
                           if(files_found)
                               try
                                   if(look4WorkFiles)
                                       curStudy = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,working_foldername,mappingStruct);                                                                  
                                   end

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
                       
                   elseif(strcmpi(src_foldertype,'flat'))
                       
                       psg_filenames = strrep(getFilenames(src_folder,strcat('*',lower(psg_ext))),lower(psg_ext),'');
                       PSG_filenames = strrep(getFilenames(src_folder,strcat('*',upper(psg_ext))),upper(psg_ext),'');
                       sta_filenames = strrep(getFilenames(src_folder,'*.sta'),'.sta','');
                       STA_filenames = strrep(getFilenames(src_folder,'*.STA'),'.STA','');
                       
                       unique_names = unique([psg_filenames(:);PSG_filenames(:);sta_filenames(:);STA_filenames(:)]);
                       
                       for u=1:numel(unique_names)
                           curStudy = [];
                           curStudy.cohortID =cohortID;
                           curStudy.dbID = databaseID;
                           curStudy.datetimefirstadded = 'now()';
                           cur_name = unique_names{u};
                           [curStudy, files_found] = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,'all', src_folder,cur_name,psg_ext);
                           if(files_found)
                               try
                                   if(look4WorkFiles)
                                       curStudy = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,working_foldername);                                                                  
                                   end

                                   CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy,mappingStruct)
                               catch me
                                   showME(me);
                                   fprintf('Failed on %s\n',cur_folder);
                               end
                           else
                               fprintf('No files found for %s: %s!\n',cur_folder,cur_name);
                           end
                           
                       end
                       
                   elseif(strcmpi(src_foldertype,'split'))
                       %go through the list of possible extensions
                       psg_names = {};
                       sta_names = {};
                       
                       if(exist(cohort_q.src_psg_foldername{c},'dir'))
                           cur_folder = cohort_q.src_psg_foldername{c};
                           psg_filenames = strrep(getFilenames(src_folder,strcat('*',lower(psg_ext))),lower(psg_ext),'');
                           PSG_filenames = strrep(getFilenames(src_folder,strcat('*',upper(psg_ext))),upper(psg_ext),'');
                           psg_names = unique([psg_filenames(:);PSG_filenames(:)]);
                       end
                       if(exist(cohort_q.src_stage_foldername{c},'dir'))
                           cur_folder = cohort_q.src_stage_foldername{c};
                           sta_filenames = strrep(getFilenames(cur_folder,'*.sta'),'.sta','');
                           STA_filenames = strrep(getFilenames(cur_folder,'*.STA'),'.STA','');
                           sta_names = unique([sta_filenames(:);STA_filenames(:)]);
                       end
                       unique_names = unique([psg_names(:); sta_names(:)]);
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
                                   [curStudy, local_files_found] = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,curExt, cur_folder,cur_name,psg_ext);
                                   files_found = files_found || local_files_found;
                               end
                           end
                           
                           if(files_found)
                               try
                                   if(look4WorkFiles)
                                       curStudy = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,working_foldername,mappingStruct);                                                                  
                                   end

                                   CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy)
                                   
                               catch me
                                   showME(me);
                                   fprintf('Failed on %s\n',cur_name);
                               end
                           else
                               fprintf('No files found for %s!\n',cur_name);
                           end
                       end
                   else
                       fprintf('unrecognized or unspecified tier type (%s)!\n',cohort_q.src_foldertype{c});
                   end
                   
               end
           end
        end
        
        %> @brief update_DatabaseInfo_T Updates the database info table based on the
        %> input text file.  The database info table contains the database
        %> access information for each cohort.
        %> @param filename Optional database information file (*.inf) which
        %> contains cohort specific database access entries.
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
        
        function [cohortStudy, files_found] = updateCohortStudySrcStruct(cohortStudy,fileExtension, foldername,studyName,psg_ext)
            
            if(nargin<4 || isempty(studyName))
                studyName = '*';
            end
            
            if(nargin<5 || isempty(psg_ext))
                psg_ext = [];
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
                    case 'psg'
                        psg_file = getFilenamesi(cur_folder,strcat(studyName,psg_ext));
                        if(~isempty(psg_file))
                            cohortStudy.src_has_psg_file = true;
                            cohortStudy.src_psg_filename = psg_file{1};
                            files_found = true;
                        end
                    case 'stage'
                        sta_file = getFilenamesi(cur_folder,strcat(studyName,'.STA'));                        
                        if(~isempty(sta_file))
                            cohortStudy.src_has_sta_file = true;
                            cohortStudy.src_sta_filename = sta_file{1};
                            files_found = true;
                        end
                    case 'sco'                        
                        sco_file = getFilenamesi(cur_folder,strcat(studyName,'.SCO'));
                        if(~isempty(sco_file))
                            cohortStudy.src_has_sco_file = true;
                            cohortStudy.src_sco_filename = sco_file{1};
                            files_found = true;
                        end
                    case 'xml'
                        xml_file = getFilenamesi(cur_folder,strcat(studyName,'.XML'));                        
                        if(~isempty(xml_file))
                            cohortStudy.src_has_xml_file = true;
                            cohortStudy.src_xml_filename = xml_file{1};
                            files_found = true;
                        end
                    case 'events'
                        evt_file = getFilenamesi(cur_folder,strcat(studyName,'.evt'));                        
                        if(~isempty(evt_file))
                            cohortStudy.src_has_evt_file = true;
                            cohortStudy.src_evt_filename = evt_file{1};
                            files_found = true;
                        end
                    otherwise
                        fprintf('Unhandled case %s\n',cur_extension);
                end
            end
        end
        
        %> @brief updateCohortSTudyWorkStruct looks for the working files generated for the current
        %> psg described by the input struct *cohortStudy* and updates the
        %> input cohortStudy argument accordingly.
        %> %param cohortStudy struct which contains the src_psg_filename
        %> @param src_name_mapper Multidimensional cell containing the src
        %> filename in the first column and any working files generated from
        %> the transformation script using available source data.  Generated
        %> files will have either .EDF, .SCO, or .STA file extensions.
        %> %retval cohortStudy struct
        function cohortStudy = updateCohortStudyWorkStruct(cohortStudy, mappingStruct)
            %find the study name
            if(cohortStudy.src_has_psg_file)
                src_file = cohortStudy.src_psg_filename;
                matched_data_cell = mappingStruct.work_cell(strcmpi(src_file,mappingStruct.src_cell));
                for n=1:numel(matched_data_cell)
                    working_filename = matched_data_cell{n};
                    [~,~,fext] = fileparts(working_filename);
                    if(exist(fullfile(cohortStudy.working_foldername,working_filename),'file'))
                        cohortStudy.(sprintf('working_has_%s_filename',fext)) = true;
                        cohortStudy.(sprintf('working_%s_filename',fext)) = working_filename;                        
                    end                    
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
        
        %> @brief Loads a mapping file.  Mapping files are used to map
        %> source psg filenames to their generated working files (e.g. .EDF,
        %> .STA, and .SCO files)
        %> @param src_mapping_file A text file with the mapping data.  Each row should contain (1) the
        %> source psg file name and extension followed by (2 to 4?) working
        %> file names and extensions.  Lines begining with the '#' character 
        %> are treated as comments and ignored.
        %> @retval mappingStruct struct that contains the mapping fields
        %> - src_cell Nx1 cell of strings
        %> - work_cell Nx1 cell of cell of strings
        %> work_cell{n,:} containing working file names that correspond to the 
        %> source psg filename listed in src_cell{n}
        %> @retval success Boolean that returns true if a mapping file is
        %> loaded successfully
        function [mappingStruct, success] = loadMappingFile(src_mapping_file)
            mappingStruct = [];
            success = false;
            if(exist(src_mapping_file,'file'))
                fid = fopen(src_mapping_file,'r');
                if(fid>0)
                    try
            
                        file_open = true;
                        
                        pat = '([^\.\s]+\.[^\.\s]+)';
                        
                        src_cell = {};
                        work_cell = {};
                        while(file_open)
                            try
                                curline = fgetl(fid);
                                if(~ischar(curline))
                                    file_open = false;
                                else
                                    tok = regexp(curline,pat,'tokens');
                                    if(numel(tok)>1 && isempty(strfind(tok{1}{1},'#')))
                                        src_cell{end+1,1} = char(tok{1});
                                        work_cell{end+1,1} = tok(1,2:end);
                                    end
                                end;
                            catch me
                                showME(me);                                
                            end
                        end;
                        flcose(fid);
                        mappingStruct.src_cell = src_cell;
                        mappingStruct.work_cell = work_cell;
                    catch me
                        showME(me);
                        fclose(fid);
                    end
                else
                    fprintf('An error occurred while trying to open the source name mapping file (%s).  Working files will not be added to the database.\n',src_mapping_file);
                end
            end
        end
    end
    
end