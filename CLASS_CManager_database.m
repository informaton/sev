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
        %> database name
        dbName = 'CManager_DB';
        %> database user
        dbUser = 'CManager_user';
        %> database user password
        dbPassword = 'CManager_password';
        %> @brief File types to use, can be
        %> @li psg @li stage @li sco @li xml @li events        
        fileTypes = {'psg','stage','sco','xml','events'};  
        %> @brief Extensions of files that will be used (i.e. after transcoding)  
        %> @li edf
        %> @li sco
        %> @li sta
        workingFileExts = {'edf','sco','sta'};
    end
    
    methods
        %> @brief Constructor
        %> @retval Instance of CLASS_CManager_database
        %> @note Initializes <b>dbStruct</b>
        function obj = CLASS_CManager_database()
            obj.dbStruct = CLASS_CManager_database.getDBStruct();
        end
        
        %> @brif Abstract method that is not implemented.
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
        %> - cohortid Primary key with constraint that name and projectname
        %> are unique
        %> - name Name of the cohort (e.g. SSC)
        %> - projectname name of the specific project (e.g. APOE)
        %> - location Geographic location where sleep studies were
        %> performed.
        %> - docking_foldername Pathname where PSG files are originally
        %> placed/held before they are moved to the source folder
        %> (src_foldername) in the first part of the migration.
        
        %> - is_docking_folder_grouped BOOL (YES/NO == 1/0)  If true, then the PSGs (regardless of their
        %> source folder type have been grouped together in separate subfolders of the docking folder.
        %> Default is NO.  In processing grouped docking folders, every
        %> folder in the docking folder is treated as if it contains PSG
        %> folders and processed according to the entry's src_foldertype property. 
        %> - src_foldername This is the system level pathname where the
        %> files from the docking folder are moved to permanently in their
        %>original format, and where transcoding scripts look to for their
        %> sorce file to transcode.
        %> - src_foldertype Can be <b>tier</b>, <b>flat</b>, or
        %> <b>split</b>.  Flat has all psg's in same folder.  Tier has each
        %> PSG in a subfolder of the main folder.  Split allows .psg, .sta, .and event files
        %> to be placed in their own folder according to their type 
        %> (e.g. .edf in one folder, .sta files in another, and .event files in another.
        %> - src_psg_foldername Folder name containing the original source
        %> (src) files for the cohort.
        %> - src_psg_extension filename extension of the psg (e.g. <b>.edf</b>)
        %> - src_stage_foldername stage foldername; used when folder type is <i>split</i>
        %> - src_events_foldername events foldername; used when folder type is <i>split</i>
        %> - src_xml_foldername xml foldername; used when folder type is <i>split</i>
        %> - src_sco_foldername sco foldername; used when folder type is <i>split</i>
        %> - working_foldername Folder name containing the files as
        %> transfomred by *transformation_script*.  
        %> - working_foldertype Either <b>split</b> or <b>flat</b>; default
        %> is <b>flat</b>
        %> - working_edf_foldername EDF foldername; used when folder type is <i>split</i>
        %> - working_sta_foldername STA foldername; used when folder type is <i>split</i>
        %> - working_sco_foldername SCO foldername; used when folder type is <i>split</i>
        %> - patient_description_file
        %> - transformation_script Name of file used to transcode src files
        %> to working files.
        %> - src_mapping_file Name of file that contains the mapping from the src psg filenames to working filenames.
        %> - psg_collection_system PSG collection suite used by cohort. enumerated ''Grass'',''Gamma'',''Twin'',''Embla Sandman'',''Woodward'',''Unknown'',''Various'') default is ''Unknown'''
        %> - pointofcontact Name and email of point of contact
        %> - notes Free form text.
        %> - reference Free form text.  Used to hold publication references
        %> related to the creation of this cohort that should be cited in
        %> research that uses this cohort.
        %> - website For holding useful http links related to the cohort.  Free form text.  
        %> - timeframe Time span of when cohort data was collected (e.g. 2000-2010 for WSC).  Free form text
        %> @note The fields should be listed in the cohort.str text file
        %> for updating; see update_CohortInfo_T
        function create_CohortInfo_T(obj)            
            obj.open();
            TableName = 'cohortInfo_T';
            TableName = lower(TableName);
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'(',...
                ' cohortid SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT',...
                ', name VARCHAR(30) NOT NULL DEFAULT "whoRwe"',...
                ', projectname VARCHAR(30) DEFAULT NULL',...                
                ', location VARCHAR(512) DEFAULT "somewhere"',...                
                ', docking_foldername varchar(128) DEFAULT NULL',...
                ', is_docking_folder_grouped BOOL DEFAULT FALSE',...
                ', src_foldername varchar(128) DEFAULT NULL',...
                ', src_foldertype ENUM(''tier'',''flat'',''split'',''group'')',...
                ', src_psg_foldername varchar(128) DEFAULT NULL',...
                ', src_psg_extension varchar(4) DEFAULT ''.EDF''',...                
                ', src_stage_foldername varchar(128) DEFAULT NULL',...
                ', src_events_foldername varchar(128) DEFAULT NULL',...
                ', src_xml_foldername varchar(128) DEFAULT NULL',...
                ', src_sco_foldername varchar(128) DEFAULT NULL',...                   
                ', working_foldername varchar(128) DEFAULT NULL',...
                ', working_foldertype ENUM(''tier'',''flat'',''split'',''group'')',...
                ', working_edf_foldername varchar(128) DEFAULT NULL',...
                ', working_sta_foldername varchar(128) DEFAULT NULL',...
                ', working_sco_foldername varchar(128) DEFAULT NULL',...
                ', patient_description_file varchar(128) DEFAULT NULL',...                
                ', transformation_script VARCHAR(128) DEFAULT NULL',...
                ', src_mapping_file VARCHAR(128) DEFAULT NULL',...                
                ', psg_collection_system ENUM(''Grass'',''Gamma'',''Twin'',''Embla Sandman'',''Woodward'',''Unknown'',''Various'') DEFAULT ''Unknown''',...
                ', pointofcontact VARCHAR(128) DEFAULT NULL',...
                ', notes VARCHAR(1024) DEFAULT NULL',...
                ', reference VARCHAR(512) DEFAULT NULL',...
                ', website VARCHAR(512) DEFAULT NULL',...
                ', timeframe VARCHAR(256) DEFAULT NULL',...                
                ', PRIMARY KEY (cohortid)',...
                ', CONSTRAINT UNIQUE (name, projectname)',...                
                ')']);
            obj.close();
        end
        
        %> @brief create_FileStudyInfo_T creates the filestudyinfo_t table.
        %> FileStudyinfo Table fields:        
        %> - uuid universal ID (primary, foreign key, can be empty?)
        %> - cohortid unique key of the cohort database each record is related to.
        %> - dbID Database Info's primary key (primary, foreign key; default is 0 which means the study is not in a database).
        %> - fileID primary key for each record
        %> - patstudykey the primary key of this record in the associated database; there is a problem with how to identify these if they are not in a database.  I see two solutions: (1.)  Build the indexing database first and then build the suboordinate, cohort databases next with the requirement that they use the same patstudykey values for their own entries.  (2.)  Leave the patstudykey blank and instead use the filename and cohort name, combined, as the primary key.
        %> - patid Cohort patient identifier
        %> - datetimelastupdated Date/time last updated. (e.g. 2014-01-27, 16:49)
        %> - datetimefirstadded Date/time Added (e.g. 2014-01-27, 16:49)        
        %> - src_sub_foldername Sub foldername of file (only used if the associated cohort entry (i.e. cohortid) has 'tier'
        %> for the src_foldertype field)
        %> - src_has_psg_file Does it come with an .edf file
        %> - src_psg_filename name of the psg file (e.g. R0017_2 080612.EDF)
        %> - src_has_sta_file Does the original record have a stage file? (yes=1/no=0)
        %> - src_sta_filename Original stage file name (empty for none)
        %> - src_has_evt_file Dose an original event file exists (yes=1/no=0)
        %> - src_evt_filename Original event file name (empty for none)
        %> - src_has_sco_file Does the original record have a .SCO file (yes=1/no=0)
        %> - src_sco_filename Original .sco filename (empty for none)
        %> - src_has_xml_file Does the original record have a .xml file (yes=1/no=0)
        %> - src_xml_filename Original .xml filename (empty for none)
        %> - working_sub_foldername sub foldername of file - only used when
        %> associated cohort entry has 'tier' for the working_foldertype
        %> field)
        %> - working_has_edf_file Does a working .edf export of the source psg exist? (yes=1/no=0)
        %> - working_edf_filename name of the .edf file
        %> - working_has_sta_file Does a working .sta (stage file) export of the source stage file exist? (yes=1/no=0)
        %> - working_sta_filename name of the .sta file
        %> - working_has_sco_file Does a working .sco export of the source record scoring data exist? (yes=1/no=0)
        %> - working_sco_filename name of the .sco file
        %> @note The table is further constrained to have a unique
        %> src_psg_filename, src_sub_foldername, and cohortid.
        function create_FileStudyInfo_T(obj) 
            obj.open();            
            TableName = 'filestudyInfo_T';
            TableName = lower(TableName);
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'(',...
                '  uID INT UNSIGNED DEFAULT NULL ',...
                ', cohortid SMALLINT UNSIGNED NOT NULL',...
                ', dbID SMALLINT UNSIGNED DEFAULT NULL',...
                ', fileID INT UNSIGNED NOT NULL AUTO_INCREMENT',...
                ', patstudykey SMALLINT UNSIGNED DEFAULT NULL',...
                ', datetimelastupdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',...
                ', datetimefirstadded TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL',...
                ', patid varchar(30) DEFAULT NULL',...
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
                ', working_sub_foldername VARCHAR(70) NULL',...
                ', working_has_edf_file BOOL DEFAULT FALSE',...
                ', working_edf_filename VARCHAR(70) DEFAULT NULL',...
                ', working_has_sta_file BOOL DEFAULT FALSE',...
                ', working_sta_filename VARCHAR(70) DEFAULT NULL',...
                ', working_has_sco_file BOOL DEFAULT FALSE',...
                ', working_sco_filename VARCHAR(70) DEFAULT NULL',...                
                ', PRIMARY KEY (fileID)',...                
                ', CONSTRAINT UNIQUE (src_psg_filename, src_sub_foldername,cohortid)',...                
                ')']);
            obj.close();
        end
        
        %> @brief create_DatabaseInfo_T create the database info table.
        %> Database Info Table fields include
        %> -   dbID - data base info's primary key (e.g. 0, 1, 2, etc)
        %> -   name - Name of the database entry (e.g. WSC_DB, SSC_DB),
        %> -   user - User name for entering database
        %> -   password - database login password for the user.
        %> -   creationScript - matlab file (and location) used to generate
        %> the database         
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
        %> input XML file.  
        %> @param filename Optional cohort structure file (*.xml) which
        %> describes each cohort according to the XML schema or DTD
        function update_CohortInfo_T(obj,xmlfilename)
            TableName = lower('CohortInfo_T');
            
            %get this from my sev file
            if(nargin<2)
                xmlfilename = uigetfullfile({'*.xml','Cohort structure file (*.xml)'},'Select cohort information structure file');
            end
            if(exist(xmlfilename,'file'))
                obj.open();
                domStruct = obj.loadCohortStruct(xmlfilename);
                if(isfield(domStruct,'cohort'))
                    cohortArrayStruct = dom.cohort;
                    for c=1:numel(cohortArrayStruct)
                        cohortStruct = cohortArrayStruct(c);
                        cohorts = fieldnames(cohortStruct);
                        for f=1:numel(cohorts)
                            curCohort = cohortStruct.(cohorts{f});
                            if(isfield(curCohort,'name'))
                                names = ' (';
                                values = '(';
                                updateClause = [' ON DUPLICATE KEY UPDATE '];
                                curFields = fieldnames(curCohort);
                                for cf=1:numel(curFields)
                                    curField = curFields{cf};
                                    curValue = curCohort.(curField);
                                    if(isnumeric(curValue))
                                        curValue = num2str(curValue);
                                    end
                                    curValue = strrep(curValue,'"','\"');
                                    names = sprintf('%s %s,',names,curField);
                                    values = sprintf('%s "%s",',values,curValue);
                                    updateClause = sprintf('%s %s="%s",',updateClause,curField,curValue);
                                end
                                names(end)=')';
                                values(end)=')';
                                updateClause(end) = []; %remove trailing ','
                                
                                insertStr = ['INSERT INTO ',TableName,names,' VALUES ',values, updateClause];
                                try
                                    mym(insertStr);
                                catch me
                                    showME(me);
                                end
                            end
                        end
                    end
                end
                obj.close();
            end                     
        end
        
        %> @brief update_CohortInfoFromStr_T Updates the cohort table based on the
        %> input text file.
        %> @param filename Optional cohort structure file (*.str) which
        %> describes each cohort using tab delimited key value pairs.
        function update_CohortInfoFromStr_T(obj,filename)
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
                            updateClause = [' ON DUPLICATE KEY UPDATE '];
                            curFields = fieldnames(curCohort);
                            for cf=1:numel(curFields)
                                curField = curFields{cf};
                                curValue = curCohort.(curField);
                                if(isnumeric(curValue))
                                    curValue = num2str(curValue);
                                end
                                curValue = strrep(curValue,'"','\"');
                                names = sprintf('%s %s,',names,curField);
                                values = sprintf('%s "%s",',values,curValue);
                                updateClause = sprintf('%s %s="%s",',updateClause,curField,curValue);
                            end
                            names(end)=')';
                            values(end)=')';
                            updateClause(end) = []; %remove trailing ','
                            
                            insertStr = ['INSERT INTO ',TableName,names,' VALUES ',values, updateClause];
                            try
                                mym(insertStr);
                            catch me
                                showME(me);
                                insertStr
                            end
                        end
                    end
                    obj.close();
                end
            end         
        end

        %> @brief Update the filestudyinfo_t table by examining folders
        %> in the cohort information available
        %> in the cohortinfo_t table.
        %> @note A file is not updated until it has been assigned to a
        %> cohort as entered in the update_CohortInfo_T call.
        function update_FileStudyInfo_T(obj)
           obj.open();
           TableName = lower('FileStudyInfo_T');
           cohort_q= mym('select * from cohortinfo_t');           
           for c = 1:numel(cohort_q.cohortid)
               cohortid = cohort_q.cohortid(c);
               database_q = mym('select dbid from databaseinfo_t where name="{S}_DB"',cohort_q.name{c});
               databaseID = database_q.dbid;
               src_foldertype = cohort_q.src_foldertype{c};
               src_foldername = cohort_q.src_foldername{c};
               
               working_foldername = cohort_q.working_foldername{c};
               working_foldertype = cohort_q.working_foldertype{c};
               src_mapping_file = cohort_q.src_mapping_file{c};
               psg_ext = cohort_q.src_psg_extension{c};
               
               
               
               %now look through the working folders...
               if(~exist(working_foldername,'dir'))
                   fprintf('Where did you go?\n');
                   fprintf('Could not find the working folder for PSGs (%s)!\n',working_foldername);
                   fprintf('No working folder found for %s!\n',cohort_q.name{c});
               else
                   
                   if(exist(src_mapping_file,'file'))  % && strcmpi(working_foldertype,'flat') 
                       [mappingStruct, look4WorkFiles] = CLASS_CManager_database.loadMappingFile(src_mapping_file);
                   else                       
                       fprintf('The source mapping file (%s) could not be found.\n',src_mapping_file);
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
                           curStudy.cohortid =cohortid;
                           curStudy.dbID = databaseID;
                           curStudy.datetimefirstadded = 'now()';                           
                           cur_folder = fullfile(src_foldername,folderNames{f});
                           curStudy.src_sub_foldername = folderNames{f};                           
                           [curStudy, files_found] = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,'all', cur_folder,psg_ext);
                           
                           if(files_found)
                               try
                                   if(look4WorkFiles)
                                       curStudy = CLASS_CManager_database.updateCohortStudyWorkStruct(curStudy,mappingStruct,working_foldername,working_foldertype);                                                                  
                                   end
                                   CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy)
                               catch me
                                   showME(me);
                                   fprintf('Failed on %s\n',cur_folder);
                               end
                           else
                               fprintf('No files found in %s!\n',cur_folder);
                           end
                       end
                       
                   %This is a MrOS type
                   elseif(strcmpi(src_foldertype,'group'))                       
                       folderGrpNames = getPathnames(src_foldername);
                       if(~iscell(folderGrpNames))
                           fprintf('Warning!  Only one group folder found for this cohort (%s)\n',folderGrpNames);
                           folderGrpNames = {folderGrpNames};
                       end
                       
                       for f=1:numel(folderGrpNames)
                           rootStudy = [];
                           rootStudy.cohortid =cohortid;
                           rootStudy.dbID = databaseID;
                           rootStudy.datetimefirstadded = 'now()';
                           
                           cur_src_foldername = fullfile(src_foldername,folderNames{f});
                           rootStudy.src_sub_foldername = folderGrpNames{f};
                           
                           %now go through each sub folder in a 'flat'
                           %fashion.
                           psg_filenames = strrep(getFilenames(cur_src_foldername,strcat('*',lower(psg_ext))),lower(psg_ext),'');
                           PSG_filenames = strrep(getFilenames(cur_src_foldername,strcat('*',upper(psg_ext))),upper(psg_ext),'');
                           sta_filenames = strrep(getFilenames(cur_src_foldername,'*.sta'),'.sta','');
                           STA_filenames = strrep(getFilenames(cur_src_foldername,'*.STA'),'.STA','');
                           
                           unique_names = unique([psg_filenames(:);PSG_filenames(:);sta_filenames(:);STA_filenames(:)]);
                           
                           for u=1:numel(unique_names)
                               
                               cur_name = unique_names{u};
                               [curStudy, files_found] = CLASS_CManager_database.updateCohortStudySrcStruct(rootStudy,'all', cur_src_foldername,cur_name,psg_ext);
                               if(files_found)
                                   try
                                       if(look4WorkFiles)
                                           curStudy = CLASS_CManager_database.updateCohortStudyWorkStruct(curStudy,mappingStruct,working_foldername,working_foldertype);
                                       end
                                       
                                       CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy);
                                       
                                       
                                   catch me
                                       showME(me);
                                       fprintf('Failed on %s\n',cur_name);
                                   end
                               else
                                   fprintf('No files found for %s: %s!\n',cur_folder,cur_name);
                               end
                               
                           end
                       end
                       
                       %This is a WSC example, where the EDF's and files are all
                       %located in the all foldername
                       
                   elseif(strcmpi(src_foldertype,'flat'))
                       
                       psg_filenames = strrep(getFilenames(src_foldername,strcat('*',lower(psg_ext))),lower(psg_ext),'');
                       PSG_filenames = strrep(getFilenames(src_foldername,strcat('*',upper(psg_ext))),upper(psg_ext),'');
                       sta_filenames = strrep(getFilenames(src_foldername,'*.sta'),'.sta','');
                       STA_filenames = strrep(getFilenames(src_foldername,'*.STA'),'.STA','');
                       
                       unique_names = unique([psg_filenames(:);PSG_filenames(:);sta_filenames(:);STA_filenames(:)]);
                       
                       for u=1:numel(unique_names)
                           curStudy = [];
                           curStudy.cohortid =cohortid;
                           curStudy.dbID = databaseID;
                           curStudy.datetimefirstadded = 'now()';
                           cur_name = unique_names{u};
                           [curStudy, files_found] = CLASS_CManager_database.updateCohortStudySrcStruct(curStudy,'all', src_foldername,cur_name,psg_ext);
                           if(files_found)
                               try
                                   if(look4WorkFiles)
                                       curStudy = CLASS_CManager_database.updateCohortStudyWorkStruct(curStudy,mappingStruct,working_foldername,working_foldertype);
                                   end
                                   CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy);
                                   
                               catch me
                                   showME(me);
                                   fprintf('Failed on %s\n',cur_name);
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
                           psg_filenames = strrep(getFilenames(src_foldername,strcat('*',lower(psg_ext))),lower(psg_ext),'');
                           PSG_filenames = strrep(getFilenames(src_foldername,strcat('*',upper(psg_ext))),upper(psg_ext),'');
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
                           curStudy.cohortid =cohortid;
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
                                       curStudy = CLASS_CManager_database.updateCohortStudyWorkStruct(curStudy,mappingStruct,working_foldername,working_foldertype);                                                                  
                                   end

                                   CLASS_CManager_database.insertRecordFromStruct(TableName,curStudy);
                                   
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
                    onDuplicateStr = 'ON DUPLICATE KEY UPDATE name=%s, user=%s, password = %s';
                    preInsertStr = ['INSERT INTO ',TableName, ' (name,user, password) VALUES ("%s", "%s", "%s") ', onDuplicateStr];
                    for n=1:num_entries
                        try
                            mym(sprintf(preInsertStr,database_struct.name{n},database_struct.user{n},database_struct.password{n},...
                                database_struct.name{n},database_struct.user{n},database_struct.password{n}));
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
        
        %> @brief Returns a database struct.
        %> @retval dbStruct A database struct with the following fields
        %> @li name Name of the database.  
        %> @li user User name for the database.
        %> @li password Password for the user to access the database.        
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
        function cohortStudy = updateCohortStudyWorkStruct(cohortStudy, mappingStruct,working_foldername,workingFolderType)
            %find the study name
            if(cohortStudy.src_has_psg_file)
                src_file = cohortStudy.src_psg_filename;
                
                %  workingFolderType = cohortStudy.working_foldertype;
                workingFilename = char(mappingStruct.work_cell(strcmpi(src_file,mappingStruct.src_cell)));  %apply the char here to remove cell structure when match is found or make empty when no match is found.  The {} operators will throw an empty assignment error in the case of no match.
                
                if(~isempty(workingFilename))
                    [~,fname,~] = fileparts(workingFilename);
                    if(strcmpi(workingFolderType,'group'))
                        
                    elseif(strcmpi(workingFolderType,'split'))
                        
                    elseif(strcmpi(workingFolderType,'tier'))
                        
                     elseif(strcmpi(workingFolderType,'flat'))
                        for e=1:numel(CLASS_CManager_database.workingFileExts)
                            fext = CLASS_CManager_database.workingFileExts{e};
                            working_filename = strcat(fname,'.',upper(fext));
                            if(exist(fullfile(working_foldername,working_filename),'file'))
                                cohortStudy.(sprintf('working_has_%s_file',fext)) = true;
                                cohortStudy.(sprintf('working_%s_filename',fext)) = working_filename;
                            end
                        end
                    end
                end
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
                        pat = '([^\.]+\.[^\.\s]+)';
                        
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
                                        src_cell{end+1,1} = strtrim(char(tok{1}));
                                        work_cell{end+1,1} = strtrim(char(tok{2}));
                                        success = true;
                                    end
                                end;
                            catch me
                                showME(me); 
                                success = false;
                            end
                        end;
                        fclose(fid);
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