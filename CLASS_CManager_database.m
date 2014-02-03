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
    end
    properties
    end
    
    methods
        function obj = CLASS_CManager_database()
            obj.dbStruct = CLASS_CManager_database.getDBStruct();
        end
        
        function makeAll(obj)
            obj.createDBandTables();
            obj.updateDBandTables();
        end
        
        function createDBandTables(obj)
            obj.create_DB();
            obj.create_StudyInfo_T();
            obj.create_FileCohortInfo_T();
            obj.create_DatabaseInfo_T();            
        end
        
        function updateDBandTables(obj)
           obj.update_CohortInfo_T();
           obj.update_FileStudyInfo_T();
           obj.update_DatabaseInfo_T();           
        end
        
        
        function update_FileStudyInfo_T(obj) 
            
            
        end
        
        function update_CohortInfo_T(obj) 
            
            
        end

        function update_DatabaseInfo_T(obj, filename) 
            %get this from my sev file
            
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
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                ' uID INT UNSIGNED DEFAULT NULL'...
                ', cohortID SMALLINT UNSIGNED DEFAULT NOT NULL'...
                ', dbID SMALLINT UNSIGNED DEFAULT NULL'...
                ', patstudykey SMALLINT UNSIGNED DEFAULT NOT NULL'...
                ', datetimefirstadded DATETIME DEFAULT CURRENT_TIMESTAMP'...
                ', datetimelastupdated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'...
                ', patid varchar(30) DEFAULT NULL'...
                ', psg_filename VARCHAR(70) NOT NULL',...
                ', event_filename VARCHAR(70) NOT NULL'...
                ', stage_filename VARCHAR(70) NOT NULL'...
                ', PRIMARY KEY (cohortID, patstudykey)'...
                ')']);
            obj.close();
        end
        
        function create_CohortInfo_T(obj)
            obj.open();
            TableName = 'cohortInfo_T';
            TableName = lower(TableName);
            mym(['DROP TABLE IF EXISTS ',TableName]);
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                ', cohortID SMALLINT UNSIGNED DEFAULT NOT NULL'...
                ', cohortname VARCHAR(30) DEFAULT "WHORWE"'...
                ', cohortlocation VARCHAR(30) DEFAULT "somewhere"'...                
                ', psg_foldername varchar(128) DEFAULT NULL'...
                ', transformation_script VARCHAR(128) DEFAULT NULL',...
                ', pointofcontact VARCHAR(128) NOT NULL'...
                ', notes VARCHAR(512) NOT NULL'...
                ', PRIMARY KEY (cohortID)'...
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
            
            mym(['CREATE TABLE IF NOT EXISTS ',TableName,'('...
                ', dbID SMALLINT UNSIGNED DEFAULT NOT NULL'...
                ', Montage_suite ENUM(''Grass'',''Gamma'',''Twin'',''Embla'',''Woodward'',''Unknown'',''APOE'',''WSC'') DEFAULT ''Unknown'''...
                ', DB_name varchar(20) not null'...
                ', DB_user varchar(20) not null'...
                ', DB_password varchar(20) not null'...                
                ', PRIMARY KEY (dbID)'...
                ')']);
            
            obj.close();
        end
    end
    
    methods(Static, Access=private)
        function dbStruct = getDBStruct()
            dbStruct.name = CLASS_WSC_database.dbName;
            dbStruct.user = CLASS_WSC_database.dbUser;
            dbStruct.password = CLASS_WSC_database.dbPassword;
        end  
    end
end



