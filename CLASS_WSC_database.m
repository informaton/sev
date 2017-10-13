%> @file CLASS_WSC_database.m
%> @brief Database development class for Wisconsin Sleep Cohort data.
% ======================================================================
%> @brief The class is designed for database development, functionality, and 
%> interaction with SEV and Wisconsin Sleep Cohort data.
%> @note: A MySQL database must be installed on the local host for class
%> instantiations to operate correctly.%>
% ======================================================================
classdef CLASS_WSC_database < CLASS_database_psg

    properties (Constant)
        %> Database name
        dbName = 'WSC_DB';
        %> Database user name
        dbUser = 'WSC_user';
        %> Database user password
        dbPassword = 'WSC_password';
    end
    properties
    end
    
    methods
        %> @brief Class constructor.
        %> @retval obj Instance of CLASS_WSC_database.
        function obj = CLASS_WSC_database()
            obj.dbStruct = CLASS_WSC_database.getDBStruct();
        end
        
        % ======================================================================
        %> @brief Streamlined version for creating a mysql database which uses
        %> mysqldump system calls to import the studyinfo_t and plm_t
        %> tables in creating the Wisconsin Sleep Cohort.  
        %> First creates WSC Database and GRANTs access to wsc_user
        %> and then CREATEs the following tables:
        %> @li  StudyInfo_T - Imported now using input filename
        %> @li  WSC_Diagnostics_T
        %> @li  StageStats_T
        %> @li  Events_T
        %> @li  Medications_T
        %> @li  DetectorInfo_T
        %> @li  SNP_T
        %> @param obj Instance of CLASS_WSC_database
        %> @param EDF_pathname Directory containing cohort of sleep studies
        %> in European Data Format, .EDF (string).
        %> @param evt_pathname Directory containing SEV format event
        %> files, .evt.*.txt (string)
        %> @param importTableNames An optional cell of mysqldump table
        %> dumps.  The corresponding files must be in the current directory
        %> For example: importTableNames = {'studyinfo_t','plm_t'} then the
        %files studyinfo_t.sql and plm_t.sql must exist in the working
        %directory to be loaded using mysqldump prior to call.
        % =================================================================
        function createDBandLiteTables(obj, EDF_pathname,evt_pathname, studyinfo_dumpfile, plm_dumpfile)
            % modified: 7/27/12
            %       - changed ordering so that studyinfo_t is created prior to
            %       diagnostics_t.  Diagnostics_t creation requires patstudykey and
            %       visitsequence fields to be pulled from studyinfo_t using (patid,
            %       studynum)
            
            % make the database for the WSC
            obj.create_DB(obj.dbStruct);
            
            system(sprintf('mysql -u%s -p%s %s < %s',obj.dbUser,obj.dbPassword,obj.dbName,studyinfo_dumpfile),'-echo');
            
            obj.open();mym('describe studyinfo_t');           
            
            obj.create_DetectorInfo_T(obj.dbStruct);
            obj.populate_SCO_DetectorInfo_T(obj.dbStruct);
            obj.open();mym('describe detectorinfo_t');
            
            obj.create_Diagnostics_T();
            obj.open();mym('describe diagnostics_t');
            
            %% gather the snp data
            %             snp_filenames_cell = {'wsc_snps_corrected.txt'
            %                 'wsc_snp_rs11693221_corrected.txt'};
            
            obj.update_Diagnostics_T_for_SNP();            
            
            %add PLM fields
            %obj.update_Diagnostics_T_for_PLM();

            % this builds the medication table using WSC meidcation list received from Simon Warby (most likely)
            % meds_filename = 'wsc_medication_listing.txt';
            obj.create_Medications_T();
            
            CLASS_WSC_database.create_SNP_T();
            
            STA_pathname = EDF_pathname;
            obj.create_and_populate_StageStats_T(STA_pathname);
            
            obj.open();mym('describe stagestats_t');
            
            obj.create_Events_T(obj.dbStruct);
            obj.open();mym('describe events_t');
            
            %% convert SCO to .evt files
            % directory to export SCO events to
            % SCO_Evt_pathname = fullfile(EDF_pathname,'Output/SCOevents');

            % SCO_pathname = EDF_pathname;
            % SCO_Evt_pathname = fullfile(SCO_pathname,'_SCO_Evt');
            % exportSCOtoEvt(SCO_pathname,SCO_Evt_pathname);            
            %             renameFiles(SCO_Evt_pathname,'Obst_Apnea','Obs_Apnea');
            %             renameFiles(SCO_Evt_pathname,'PLME','PLM');
            
            if(~isempty(evt_pathname))
                obj.populate_Events_T(evt_pathname,obj.dbStruct);
            end
            
            obj.create_Bloodiron_T();

            system(sprintf('mysql -u%s -p%s %s < %s',obj.dbUser,obj.dbPassword,obj.dbName,plm_dumpfile),'-echo');
            
        end
        
        % ======== ABSTRACT implementations for WSC_database =========
        % ======================================================================
        %> @brief Create a mysql database and tables for the Wisconsin
        %> sleep Cohort.  First creates WSC Database and GRANTs access to wsc_user
        %> and then CREATEs the following tables:
        %> @li  StudyInfo_T
        %> @li  WSC_Diagnostics_T
        %> @li  StageStats_T
        %> @param obj Instance of CLASS_WSC_database
        %> @param EDF_pathname Directory containing cohort of sleep studies
        %> in European Data Format, .EDF (string).
        %> @param evt_pathname Directory containing SEV format event
        %> files, .evt.*.txt (string)
        % =================================================================
        function createDBandTables(obj,EDF_pathname,evt_pathname)
            % modified: 7/27/12
            %       - changed ordering so that studyinfo_t is created prior to
            %       diagnostics_t.  Diagnostics_t creation requires patstudykey and
            %       visitsequence fields to be pulled from studyinfo_t using (patid,
            %       studynum)
            % make the database for the WSC
            if(nargin<3)
                disp('Select Event directory (*.evt)');
                evt_pathname =uigetdir(pwd,'Select Event directory (*.evt) to use or Cancel for none.');
                if(isnumeric(evt_pathname) && ~evt_pathname)
                    evt_pathname = [];
                end

                if(nargin<2)
                    disp('Select PSG directory (Contains *.EDF and *.STA files)');
                    EDF_pathname =uigetdir(evt_pathname,'Select .EDF directory to use');
                    if(isnumeric(EDF_pathname) && ~EDF_pathname)
                        EDF_pathname = [];
                    end
                end
            end
            
            obj.create_DB();
            
            %% these functions create the named tables
            %these functions create the named tables
            
            obj.create_StudyInfo_T(obj.dbStruct);           
            obj.populate_StudyInfo_T(obj.dbStruct,EDF_pathname,'WSC');           
            obj.open();mym('describe studyinfo_t');           
            
            obj.create_DetectorInfo_T(obj.dbStruct);
            obj.populate_SCO_DetectorInfo_T(obj.dbStruct);
            obj.open();mym('describe detectorinfo_t');
            
            obj.create_Diagnostics_T();
            obj.open();mym('describe diagnostics_t');
            
            %% gather the snp data
            %             snp_filenames_cell = {'wsc_snps_corrected.txt'
            %                 'wsc_snp_rs11693221_corrected.txt'};
            
            obj.update_Diagnostics_T_for_SNP();            
            
            %add PLM fields
            %obj.update_Diagnostics_T_for_PLM();

            % this builds the medication table using WSC meidcation list received from Simon Warby (most likely)
            % meds_filename = 'wsc_medication_listing.txt';
            obj.create_Medications_T();
            
            CLASS_WSC_database.create_SNP_T();
            
            STA_pathname = EDF_pathname;
            obj.create_and_populate_StageStats_T(STA_pathname);
            
            obj.open();mym('describe stagestats_t');
            
            obj.create_Events_T(obj.dbStruct);
            obj.open();mym('describe events_t');
            
            %% convert SCO to .evt files
            % directory to export SCO events to
            % SCO_Evt_pathname = fullfile(EDF_pathname,'Output/SCOevents');

            % SCO_pathname = EDF_pathname;
            % SCO_Evt_pathname = fullfile(SCO_pathname,'_SCO_Evt');
            % exportSCOtoEvt(SCO_pathname,SCO_Evt_pathname);            
            %             renameFiles(SCO_Evt_pathname,'Obst_Apnea','Obs_Apnea');
            %             renameFiles(SCO_Evt_pathname,'PLME','PLM');
            
            if(~isempty(evt_pathname))
                obj.populate_Events_T(evt_pathname,obj.dbStruct);
            end
            
            obj.create_Bloodiron_T();
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
            
            TableName = 'Medications_T';
            TableName = lower(TableName);
            
            if(nargin==1 || isempty(meds_filename))
                [meds_filename, pathname, ~] = uigetfile({'*.txt','Tab-delimited Text (*.txt)'},'Select Medications list data file','MultiSelect','off');
                
                if(isnumeric(meds_filename) && ~meds_filename)
                    meds_filename = [];
                else
                    meds_filename = fullfile(pathname,meds_filename);
                end
            end
            
            if(exist(meds_filename,'file'))
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
                TStr = sprintf('CREATE TABLE IF NOT EXISTS %s (patstudykey smallint unsigned not null,',TableName);
                column_names_db_string = 'patstudykey';
                
                for n=2:numel(column_names)
                    name = char(column_names{n});
                    TStr = sprintf('%s %s bool default null,',TStr,name);
                    column_names_db_string = sprintf('%s,%s',column_names_db_string,name);
                end
                
                TStr = sprintf('%s PRIMARY KEY (PATSTUDYKEY))',TStr);                
                
                mym(['DROP TABLE IF EXISTS ',TableName]);
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
                        mym(sprintf('insert into %s (%s) values (%s)',TableName,column_names_db_string,valuesStr));
                    end
                end
            else
                fprintf('Medications text file not provided or found');
            end
        end
        
        % ======================================================================
        %> @brief Creates Diagnostic_T table for the WSC database and populates it 
        %> from the WSC datashseet file provided by Wisconsin Sleep Cohort.
        %> @note The filename of the .xls was changed to have different
        %> column order and be tab-delimited, and saved to 'wsc_datasheet.txt',
        %> which must be in the same directory as this function. 
        %> @param obj Instance of CLASS_WSC_database
        %> @param diagnostics_xls_filename File name of .xls file with WSC subject information
        %> to populate Diagnostic_T table with (string).
        %> @note  The created table Diagnostics_T is added to the WSC_DB database.  Any previously existing
        %> table with the same name is first dropped.
        % =================================================================
        function create_Diagnostics_T(obj, diagnostics_xls_filename)
            % this builds the Diagnostics table
            %
            % Author: Hyatt Moore IV
            % created 12/27/11
            
            % Edited:
            %   8/31/12 - using new file from Laurel at WSC as input.
            %   8/23/12 - changed RLS symptom severity to broad and narrow fields
            %       Broad means both categories (question A and question B) have to be
            %       met, and narrow means just category 1 needs to be met.
            %   7/26-7/27/12 - incorporate medication fields received from WSC -
            %       moved away from sql's load file method and wrote code to parse
            %       each file myself.  The load file was missing studies here and there
            %       and did not provide enough flexibility on the programming side (I
            %       had to change things in the file most of the time instead).
            %   -wsc_datasheet.xls must have the header rows labeled the same as the
            %   field names used to create the diagnostic table, which are shown in
            %   this source code.
            %   -excel file must be saved using excel 2011 format for a mac or have the
            %   pivot/source year be listed as 1/1/1900 (not 1904 as on previous excel versions
            %   for the mac).  This is a non-issue when using windows excel.
            %   -studyinfo_t table must be created first.  the patstudykey and
            %   visitsequence values are pulled from it.
            %   - 'wsc_snps_corrected.txt' file must first be generated using the
            %   convertSNPFile2WSCFile.m script, which changes names of PatID's and
            %   translates snp values into numeric values as:
            %       major-major = 0
            %       major-minor = 1
            %       minor-minor = 2
            %
            %: 1/5/12
            
            
            obj.open();
            
            %create the table now for the first time
            
            % csv_filename = 'wsc_datasheet.csv';
            % convert_blank_to_null_in_csv(csv_filename)
            
            %             xls_filename = fullfile('/Volumes/Macintosh HD 2/Sleep/PLM/DataFiles','Hyatt data 9 2013.xls');
            
            if(nargin<2 || isempty(diagnostics_xls_filename))
                [wsc_filename, pathname, ~] = uigetfile({'*.xls','Microsoft Excel (*.xls)';'*.xlsx','Microsoft Excel (*.xlsx)'},'Select WSC Diagnostics File');
                
                if(isnumeric(wsc_filename) && ~wsc_filename)
                    wsc_filename = [];
                else
                    wsc_filename = fullfile(pathname,wsc_filename);
                end
            else
                wsc_filename = diagnostics_xls_filename;
            end
            if(exist(wsc_filename,'file'))
                
                [num,txt,raw]=xlsread(wsc_filename);
                
                hdr = raw(1,:);
                
                tableName = 'diagnostics_t';
                
                % BIT, TINYINT(1), BOOL, AND BOOLEAN ARE AL THE SAME
                % TINYINT IS A BYTE
                mym(['DROP TABLE IF EXISTS ',tableName]);
                
                %' Patstudykey UNSIGNED NOT NULL AUTO_INCREMENT,'
                
                char5Group = {'patid'};
                
                dateGroup = {'SLEEP_LAB_DATE'};
                
                char2fmtUGroup = {'COMMENT1'
                    'COMMENT2'
                    'COMMENT3'
                    'OTHER_HELP1'
                    'OTHER_HELP2'
                    'OTHER_HELP3'
                    'PROB_CODE1'
                    'PROB_CODE2'
                    'PROB_CODE3'
                    'SD_CODE1'
                    'SD_CODE2'
                    'SD_CODE3'
                    };
                
                udecimalGroup={'AHI4'
                    'AHI4_ADJUSTED_V2'
                    'bmi'
                    'doze_sc'
                    'age'
                    };
                
                uintGroup = {'studynum'
                    'TYPE_SHIFT'
                    'caffeine_cups_cans'
                    'zung'
                    'S3Q13A'
                    'S3Q13B'
                    'S3Q13C'
                    'S3Q13D'
                    'S3Q13E'
                    };
                
                MFGroup = {'SEX'};
                
                YNGroup = {'DIETING_AIDS'
                    'SLEEP_AIDS'
                    'STIMULANTS'
                    'DIABETES_YND'
                    };
                
                boolDefaultFalseGroup = {'rls_sleep_disorder'
                    'del'
                    'CPAP'
                    'tca_drug'
                    'ssria_drug'
                    'ssri_drug'
                    'opiode_drug'
                    'bp_drug'
                    'bd_drug'
                    'az_drug'
                    'apd_drug'
                    'antihis_drug'
                    'antipsycho_drug'
                    'ad_drug'
                    'parkinson_drug'
                    };
                
                xlsGroups = {char5Group
                    dateGroup
                    char2fmtUGroup
                    udecimalGroup
                    uintGroup
                    MFGroup
                    YNGroup
                    boolDefaultFalseGroup
                    };
                
                xlsSQLformats = {'CHAR(5) NOT NULL'
                    'DATE'
                    'CHAR(2) DEFAULT NULL'
                    'DECIMAL (6,3) UNSIGNED DEFAULT NULL'
                    'TINYINT UNSIGNED DEFAULT NULL'
                    'ENUM (''M'',''F'')'
                    'ENUM (''Y'',''N'')'
                    'BOOL DEFAULT FALSE'
                    };
                
                xlsColumnFmts = {'%s'
                    '%s'
                    '%u'
                    '%0.3f'
                    '%u'
                    '%c'
                    '%c'
                    '%u'
                    };
                
                %add for additional - not loaded from .xls
                smalluintNotNullAdd = {'patstudykey'};
                tinyuintNotNullAdd = {'visitsequence'};
                boolDefaultNullAdd = {
                    'rls_ab_monthly'
                    'rls_a_weekly'
                    };
                boolDefaultFalseAdd = {
                    'rls_A' %definite RLS
                    'rls_B' %maybe RLS
                    'rls_C' %not RLS
                    'rls_D' %missing
                    'rls_F' %uncategorized
                    };
                udecimalAdd = {'rls_ab_monthly_severity'
                    'rls_a_weekly_severity'};
                addGroups = {
                    smalluintNotNullAdd
                    tinyuintNotNullAdd
                    boolDefaultNullAdd
                    udecimalAdd
                    boolDefaultFalseAdd
                    };
                addColFmts = {'%u'
                    '%u'
                    '%u'
                    '%0.3f'
                    '%u'};
                
                addSQLFmts = {
                    'SMALLINT UNSIGNED NOT NULL'
                    'TINYINT UNSIGNED NOT NULL'
                    'BOOL DEFAULT NULL'
                    'DECIMAL (6,3) UNSIGNED DEFAULT NULL'
                    'BOOL DEFAULT FALSE'
                    };
                
                
                try
                    
                    %table create string
                    TStr = sprintf('CREATE TABLE IF NOT EXISTS %s (',tableName);
                    for g=1:numel(xlsSQLformats)
                        cur_hdr = xlsGroups{g};
                        sqlTable_format = xlsSQLformats{g};
                        hdr_fmt = xlsColumnFmts{g};
                        
                        for c=1:numel(cur_hdr)
                            TStr = sprintf('%s %s %s,',TStr,cur_hdr{c},sqlTable_format);
                            loadStruct.(cur_hdr{c}).fmt = hdr_fmt;
                            loadStruct.(cur_hdr{c}).value = raw(2:end,strcmpi(cur_hdr{c},hdr));
                        end
                    end
                    
                catch me
                    disp(me)
                end
                
                %get the RLS symptoms
                
                try
                    loadStruct = obj.scoreRLSsymptoms(loadStruct);
                catch me
                    disp(me)
                end
                for g=1:numel(addSQLFmts)
                    cur_hdr = addGroups{g};
                    sqlTable_format = addSQLFmts{g};
                    hdr_fmt = addColFmts{g};
                    for c=1:numel(cur_hdr)
                        TStr = sprintf('%s %s %s,',TStr,cur_hdr{c},sqlTable_format);
                        loadStruct.(cur_hdr{c}).fmt = hdr_fmt;
                    end
                end
                
                TStr = sprintf('%s PRIMARY KEY (PATSTUDYKEY))',TStr);
                
                mym(lower(TStr));
                
                %Excel stores dates as the number of days elapsed from 1/1/1900 - where
                %this date has a value of 00001.  And I need to subtract 2, in order to get
                %the correct date entered.
                excel_pivot_year=datenum('01.01.1900','mm.dd.yyyy')-2;
                
                patid = loadStruct.patid.value;
                studynum = loadStruct.studynum.value;
                numPatid = numel(patid);
                
                loadStruct.patstudykey.value = cell(numPatid,1);
                % loadStruct.patstudykey.fmt = '%u';
                loadStruct.visitsequence.value = cell(numPatid,1);
                
                fields = fieldnames(loadStruct);
                columnStr = ''; % keep track of the columns I will be adding into one at a time...
                
                %build the column str now, based on the traversal order of the fields
                for f=1:numel(fields)
                    columnStr = sprintf('%s,%s',columnStr,fields{f});
                end
                columnStr = columnStr(2:end);  %remove leading ','
                
                try
                    for k=1:numPatid
                        q = mym('select patstudykey, visitsequence from studyinfo_t where patid="{S}" and studynum={Si}',patid{k},studynum{k});
                        
                        if(~isempty(q.patstudykey))
                            loadStruct.visitsequence.value{k} = q.visitsequence;
                            loadStruct.patstudykey.value{k} = q.patstudykey;
                            
                            valuesStr = '';
                            
                            for f=1:numel(fields)
                                try
                                fmt = loadStruct.(fields{f}).fmt;
                                value = loadStruct.(fields{f}).value{k};
                                catch me
                                    showME(me);
                                end
                                if(strcmpi(fields{f},'SLEEP_LAB_DATE'))
                                    value = ['"',datestr(value+excel_pivot_year,'yyyy-mm-dd'),'"'];
                                elseif(isempty(value)||any(isnan(value)))
                                    value = 'NULL';
                                    fmt = '%s';
                                elseif(strcmp(fmt,'%s')||strcmp(fmt,'%c'))
                                    value = ['"',value,'"'];
                                    fmt = '%s';
                                end
                                valuesStr = sprintf(['%s,',fmt],valuesStr,value);
                            end
                            valuesStr = valuesStr(2:end);
                            try
                                mym(sprintf('insert into diagnostics_t (%s) values (%s)',columnStr,valuesStr));
                            catch me
                                me.stack
                                me.message
                                disp(me);
                            end
                        else
                            fprintf(1,'%s-%u does not have an .EDF\n',patid{k},studynum{k});
                        end
                    end
                catch me
                    showME(me);
                end
                
                mym('select studynum from diagnostics_t where patid="C9307"')
                
                % mym('select * from diagnostics_t WHERE RLS_sleep_Disorder=1 order by PATID  limit 10');
                mym('select * from diagnostics_t order by PATID  limit 10');
                mym('CLOSE');
                
                fclose all;
            else
                disp('Diagnostic input file either not provided or found.');
            end
            
        end
        
        %> @brief Builds the blood iron table (Blood_T) from the datashseet (.xls) that Jason Li
        %> compiled from the assay kits to test iron, ferritin, serum levels in the
        %> WSC.  
        %> @param obj CLASS_WSC_database instance
        %> @param blood_xls_filename Filename of .xls file with blood iron
        %> measures taken by Jason (string)
        %> @note Blood_T is overwritten in the case it already exists (i.e.
        %> first dropped, then created)
        function create_Bloodiron_T(obj,blood_xls_filename)
            %
            % Author: Hyatt Moore IV
            % created 7/31/12
            % modified: 8/28/12 - dropped transferrin field
            % modified: 11/13/12
            % modified: 12/04/12 - new file from Jason
            
            %create the table now for the first time
            obj.open();
            
            %Default values originally used with Jason            
            if(nargin<2 || isempty(diagnostics_xls_filename))
                %                 xls_filename = 'all_available_WSC_with_patids_testdates_and_priority-ling1-jl-12-10b.xls'; %provided by Jason on 12/14/2012
                %                 wsc_blood_filename = fullfile(data_path,xls_filename);
                [blood_xls_filename, pathname, filterindex] = uigetfile({'*.xls','Microsoft Excel (*.xls)';'*.xlsx','Microsoft Excel (*.xlsx)'},'Select WSC Blood data file');
                
                if(isnumeric(blood_xls_filename) && ~blood_xls_filename)
                    blood_xls_filename = [];
                else
                    blood_xls_filename = fullfile(pathname,blood_xls_filename);
                end
            end
            
            %             data_path = '/Volumes/Macintosh HD 2/Sleep/PLM/DataFiles';
            % Important columns to get are serum iron, ferritin, ln ferritin, transferrin, TSAT, CRP mean, ln CRP, and TIBC.
            %             xls_filename = 'all_available_WSC_with_patids_testdates_and_priority-ling1-jl-12-10.xls'; %provided by Jason on 12/12/2012
            %             blood_xls_filename = fullfile(data_path,xls_filename);
            

            if(exist(blood_xls_filename,'file'))
                
                tableName = 'bloodiron_t';
                
                mym(['DROP TABLE IF EXISTS ',tableName]);
                
                mym(['CREATE TABLE IF NOT EXISTS ',tableName,'('...
                    ' PatStudyKey SMALLINT UNSIGNED NOT NULL'...
                    ', serumiron DECIMAL (6,3) UNSIGNED'...
                    ', serumiron_new DECIMAL (6,3) UNSIGNED'...
                    ', ferritin DECIMAL (6,2) UNSIGNED'...
                    ', ln_ferritin DECIMAL (6,3) UNSIGNED'...
                    ', ferritin_mod DECIMAL (6,2) UNSIGNED'...
                    ', ln_ferritin_mod DECIMAL (6,3) UNSIGNED'...
                    ', transferrin DECIMAL (6,3) UNSIGNED'...
                    ', tsat DECIMAL (6,3) UNSIGNED'...
                    ', tibc DECIMAL (6,3) UNSIGNED'...
                    ', tsat_new DECIMAL (6,3) UNSIGNED'...
                    ', tibc_new DECIMAL (6,3) UNSIGNED'...
                    ', crp DECIMAL (10,2) UNSIGNED'...
                    ', ln_crp DECIMAL (6,3) UNSIGNED'...
                    ', any_cvd BOOL default true'...
                    ', any_vascular BOOL default true'...
                    ', hbp BOOL default true'...
                    ', PRIMARY KEY (PatStudyKey)'...
                    ')']);

                [num,txt,raw]=xlsread(blood_xls_filename);
                
                
                hdr = raw(1,:);
                
                fields_out = {'patstudykey';
                    'serumiron';
                    'serumiron_new';
                    'ferritin';
                    'ln_ferritin';
                    'ferritin_mod';
                    'ln_ferritin_mod';
                    'transferrin';
                    'tsat';
                    'tibc';
                    'tsat_new';
                    'tibc_new';
                    'crp';
                    'ln_crp';
                    'any_cvd';
                    'any_vascular';
                    'hbp';
                    };
                
                fields_fmt = {'%u';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%0.3f';
                    '%u';
                    '%u';
                    '%u'};
                
                fields_in = fields_out;
                fields_in{1} = 'patstudykey';
                fields_in{2} = 'serum_iron';
                fields_in{3} = 'serum_iron_new';
                fields_in{4} = 'ferritin_mean';
                fields_in{5} = 'ln_ferritin';
                fields_in{6} = 'ferritin_mod';
                fields_in{7} = 'ln_ferritin_mod';
                fields_in{8} = 'transferrin';
                fields_in{9} = 'tsat';
                fields_in{10} = 'tibc';
                fields_in{11} = 'tsat_new';
                fields_in{12} = 'tibc_new';
                fields_in{13} = 'crp_mean';
                fields_in{14} = 'ln_crp';
                fields_in{15} = 'any_cvd';
                fields_in{16} = 'any_vascular';
                fields_in{17} = 'hbp';

                
                columnNames = '';
                
                patid_ind = find(strcmpi('ID1',hdr));
                patid = raw(2:end,patid_ind);
                study_ind = find(strcmpi('visit#',hdr));
                study_num = raw(2:end,study_ind);
                
                for f=1:numel(fields_out)
                    field_out = fields_out{f};
                    field_in = fields_in{f};
                    
                    loadStruct.(field_out).value = raw(2:end,strcmpi(field_in,hdr));
                    loadStruct.(field_out).fmt= fields_fmt{f};
                    columnNames = sprintf('%s,%s',columnNames,field_out);
                end
                
                loadStruct.patstudykey.value = cell(numel(patid),1);
                columnNames = columnNames(2:end);
                try
                    for k=1:numel(patid)
                        q = mym('select patstudykey from studyinfo_t where patid="{S}" and studynum={Si}',patid{k},study_num{k});
                        if(~isempty(q.patstudykey))
                            loadStruct.patstudykey.value{k} = q.patstudykey;
                            
                            valuesStr = '';
                            
                            for f=1:numel(fields_out)
                                fmt = loadStruct.(fields_out{f}).fmt;
                                if(strcmp(fields_out{f},'has_good_iron_sample'))
                                    value = ~isnan(loadStruct.serum.value{k}) && ~isempty(loadStruct.serum.value{k});
                                else
                                    value = loadStruct.(fields_out{f}).value{k};
                                    if(strcmp(fields_in{f},'have serum'))
                                        if(value~=1)
                                            value = 0;
                                        end
                                    elseif(isnumeric(value))
                                        if(isempty(value)||isnan(value))
                                            value ='NULL';
                                            fmt = '%s';
                                        end
                                    end
                                end
                                valuesStr = sprintf(['%s,',fmt],valuesStr,value);
                            end
                            valuesStr = valuesStr(2:end);
                            try
                                mym(sprintf('insert into %s (%s) values (%s)',tableName, columnNames,valuesStr));
                            catch me
                                me.stack
                                me.message
                                disp(me);
                            end
                        else
                            fprintf(1,'%s-%u does not have an .EDF\n',patid{k},study_num{k});
                        end
                    end
                catch me
                    showME(me);
                    %     me.stack
                    %     me.message
                    %     disp(me);
                end
                
                
                mym('select * from {S} limit 10',tableName);
                mym('CLOSE');
                fclose all;
            else
                disp('Blood input file either not provided or found.');
            end
        end
        
        %%Update functions
        % ======================================================================
        %> @brief Updates the Diagnostics_T table with single nucleotide
        %> polymorphisms (SNPs) provided in the filenames for WSC subjects.
        %> @param obj CLASS_database derived instance
        %> @param snp_filenames_cell Cell of filenames (.txt) with WSC data
        %> (cell of strings)
        % =================================================================
        function update_Diagnostics_T_for_SNP(obj,snp_filenames_cell)
            if(mym)
                obj.open();
            end
            
            tableName = 'diagnostics_t';
            
            if(nargin==1 || isempty(snp_filenames_cell))
                [snp_filenames_cell, pathname, ~] = uigetfile({'*.txt','Tab-delimited Text (*.txt)'},'Select WSC SNP data file(s)','MultiSelect','on');
                
                if(isnumeric(snp_filenames_cell) && ~snp_filenames_cell)
                    snp_filenames_cell = [];
                else
                    if(~iscell(snp_filenames_cell))
                        snp_filenames_cell = fullfile(pathname,snp_filenames_cell);
                    else
                        for k=1:numel(snp_filenames_cell)
                            snp_filenames_cell{k} = fullfile(pathname,snp_filenames_cell{k});
                        end
                    end
                end
            end
%                 snp_filenames_cell = {'wsc_snps_corrected.txt'
%                     'wsc_snp_rs11693221_corrected.txt'};
%                 %     snp_filenames_cell = {'wsc_snp_rs11693221_corrected.txt'};
                
                
            if(~iscell(snp_filenames_cell))
                snp_filenames_cell = {snp_filenames_cell};
            end
            
            for s=1:numel(snp_filenames_cell)
                snp_filename = snp_filenames_cell{s};
                if(exist(snp_filename,'file'))
                    fid = fopen(snp_filename,'r');
                    firstLine = fgetl(fid);
                    snp_hdr_tokens = regexp(firstLine,'(\S+)','tokens');
                    frewind(fid);
                    data=textscan(fid,repmat('%s',1,numel(snp_hdr_tokens)),'headerlines',0,'delimiter','\t');
                    fclose(fid);
                    
                    %column1 is patid, column2 is case/control, column3 -> end are snps
                    snp_patid = data{1};
                    status = data{2};
                    
                    q = mym(sprintf(['SELECT count(*) as count FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = "WSC_DB"'...
                        ' AND TABLE_NAME = "%s" AND COLUMN_NAME = "%s"'],tableName,'has_snp'));
                    if(q.count==0)
                        mym('alter table {S} add (has_snp bool default false, casecontrol_snp enum ("case","control"))',tableName);
                    end
                    columnValueTemplate = 'has_snp=1,casecontrol_snp="%s"';
                    snpColumnDefinitionStr = '';
                    
                    snp_data = data(3:end);
                    for k=1:numel(snp_data)
                        q = mym(sprintf(['SELECT count(*) as count FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = "WSC_DB"'...
                            ' AND TABLE_NAME = "Diagnostics_T" AND COLUMN_NAME = "%s"'],snp_data{k}{1}));
                        if(q.count==0)
                            snpColumnDefinitionStr = sprintf('%s, %s TINYINT DEFAULT NULL',snpColumnDefinitionStr,snp_data{k}{1});
                            columnValueTemplate = sprintf('%s, %s=%%c',columnValueTemplate,snp_data{k}{1});
                        end
                    end
                    
                    snpColumnDefinitionStr = snpColumnDefinitionStr(3:end);
                    
                    mym('alter table diagnostics_t add ({S})', snpColumnDefinitionStr);
                    
                    num_snps = numel(snp_data);
                    values= cell(num_snps,1);
                    
                    for k=2:numel(snp_patid)
                        for snp_col=1:num_snps
                            datum = snp_data{snp_col}{k};
                            if(isempty(datum))
                                datum='$';
                            end
                            values{snp_col} = datum;
                        end
                        columnValueStr = sprintf(columnValueTemplate,status{k},char(values));
                        columnValueStr = strrep(columnValueStr,'$','NULL');
                        try
                            mym(sprintf('update diagnostics_t set %s where patid="%s"',columnValueStr, snp_patid{k}));
                        catch me
                            me.stack
                            me.message
                            disp(me)
                        end
                    end
                else
                   fprintf('Could not find %s\n',snp_filename); 
                end
            end
        end
        
        % ======================================================================
        %> @brief Updates the Diagnostics_T table with periodic leg movements (PLM)
        %> obtained automatically for a given detector applied to WSC studies
        %> @param obj CLASS_database derived instance
        %> @param detector (optional) Structure with field for identifying
        %> the detector used in obtaining PLM
        %> @li @c detector.id Detector ID used for obtaining PLM as listed
        %> in detectorInfo_T table and derived by SEV (integer) {146}
        %> @param resp (optional) Structure with fields identifying
        %> respiratory deectors used in calculating PLMs (i.e. removing
        %> overlap between apneas and related leg movements)
        %> @li @c resp.label Name of the respiratory events excluded by detector (string)
        %> @li @c resp.id Detector ID found in detectorInfo_T for the
        %> respiratory detector used.
        %> @li @c resp.whereInStr obtained via @code resp.whereInStr =
        %> makeWhereInString(resp.id,'numeric'); @endcode
        % =================================================================
        function update_WSC_Diagnostics_T_for_PLM(obj,detector,resp)
            if(mym)
                obj.open();
            end
            if(nargin==1)
                
                
                %     IF NOT EXISTS( (SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
                %     AND COLUMN_NAME='my_additional_column' AND TABLE_NAME='my_table_name') ) THEN
                %     ALTER TABLE my_table_name ADD my_additional_column varchar(2048) NOT NULL DEFAULT '';
                %     END IF;
                
                q = mym('select column_name from information_schema.columns where table_schema=database() and column_name ="auto_plmw" and table_name="diagnostics_t"');
                if(isempty(q.column_name));
                    mym(['alter table diagnostics_t add (',...
                        'auto_plmw DECIMAL (6,3) UNSIGNED DEFAULT NULL,',...
                        'auto_plms DECIMAL (6,3) UNSIGNED DEFAULT NULL,',...
                        'auto_plmswaso DECIMAL (6,3) UNSIGNED DEFAULT NULL)']);
                end
            end
            
            
            if(nargin<=2)
                resp.label = {'SCO_Central_Apnea','SCO_Hypopnea','SCO_Mixed_Apnea','SCO_Obs_Apnea'};
                q = mym(sprintf('select detectorid from detectorinfo_t where detectorlabel in %s',makeWhereInString(resp.label,'string')));
                resp.id = q.detectorid;
                resp.whereInStr = makeWhereInString(resp.id,'numeric');
            end
            
            if(nargin<=1)
                detector.id = 146;
            end
            
            tableName = 'diagnostics_t';
            plm_types = {'plmw','plms','plmswaso'};
            fieldNames = {'auto_plmw','auto_plms','auto_plmswaso'};
            
            keyFieldName = 'patstudykey';
            q = mym('select patstudykey from diagnostics_t');
            patstudykeys = q.patstudykey;
            
            try
                for p = 1:numel(plm_types)
                    plmi = getPLMI(detector,patstudykeys,resp,plm_types{p});
                    okay_plmi = plmi(~isnan(plmi));
                    okay_patstudykeys = patstudykeys(~isnan(plmi));
                    obj.updateDBTableFieldValues(tableName,fieldNames{p},okay_plmi,keyFieldName,okay_patstudykeys);
                end
                
            catch me
                showME(me);
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
            % modified 6/13/2014 - Placed in CLASS_WSC_database.m
            
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
        
    end
    
    methods(Static)
        
        %> @brief Open a mysql connection to the WSC database.
        %> @note mym is used as interface between mysql and database.
        function staticOpen()
            CLASS_database.close();
            CLASS_database.openDB(CLASS_WSC_database.getDBStruct);
        end
        
        % ======================================================================
        %> @brief This builds the SNP mapping table (SNP_Mapping_T) from the SNP mapping text file.
        %> Any previously existing table with the same name is first dropped.
        %>
        %>   - 'wsc_snps_mapping.txt' file must first be generated using the
        %>   convertSNPFile2WSCFile.m script. The file contains 1 header row and 4
        %>   columns:
        %>   Header row is SNP MajorMajor(0) MajorMinor(1) MinorMinor(2)
        %>
        %>       major-major = 0
        %>       major-minor = 1
        %>       minor-minor = 2
        %>
        %> @note This is a helper function for create_Diagnostics_T and
        %> is not designed for external use.  
        function create_SNP_T(snpMappingFilename)
            if(nargin==0 || isempty(snpMappingFilename))
                [snpMappingFilename, pathname, ~] = uigetfile({'*.txt','Tab-delimited Text (*.txt)'},'Select SNP mapping file (e.g. wsc_snps_mapping.txt)','MultiSelect','off');
            end

            % Author: Hyatt Moore IV
            % created 8/20/12
            % updated 6/6/2013 - added risk allele column
            % updated 10/09/2013 - added a field for rs11693221 (MEIS, 2)
            %create the table now for the first time            
            
            if(isnumeric(snpMappingFilename) && ~snpMappingFilename)                
                fprintf('No SNP mapping file entered or found.  The table SNP_T has not been (re)created.\n');
            else
                snpMappingFilename = fullfile(pathname,snpMappingFilename);
                
                CLASS_WSC_database.staticOpen();
                
                
                %get the snp mapping data
                fid = fopen(snpMappingFilename,'r');
                snp_data=textscan(fid,'%s\t%s\t%s\t%s\t%s\n','headerlines',1,'delimiter','\t'); %updated to get risk allele column
                fclose(fid);
                
                %extra information...
                wsc_snps = [
                    {'rs3923809','BTBD9','6'}
                    {'rs9296249','BTBD9','6'}
                    {'rs9357271','BTBD9','6'}
                    {'rs3104767','TOX3/BC034767','16'}
                    {'rs3104774','TOX3/BC034767','16'}
                    {'rs3104788','TOX3/BC034767','16'}
                    {'rs2300478','MEIS1','2'}
                    {'rs6710341','MEIS1','2'}
                    {'rs12469063','MEIS1','2'}
                    {'rs11693221','MEIS1','2'}  %added this one
                    {'rs6494696','MAP2K5/SKOR1','15'}
                    {'rs6747972','no gene','2'}
                    {'rs4626664','PTPRD','9'}
                    {'rs1975197','PTPRD','9'}
                    ];
                
                %prep the database table
                tableName = 'snp_mapping_t';
                
                mym(['DROP TABLE IF EXISTS ',tableName]);
                
                mym(['CREATE TABLE IF NOT EXISTS ',tableName,'('...
                    '  SNP VARCHAR(20) NOT NULL'...
                    ', gene VARCHAR(20) default NULL'...
                    ', chromosome tinyint unsigned default null'...
                    ', MAJORMAJOR CHAR(2) DEFAULT NULL'...
                    ', MAJORMINOR CHAR(2) DEFAULT NULL'...
                    ', MINORMINOR CHAR(2) DEFAULT NULL'...
                    ', RISKALLELE CHAR(1) DEFAULT NULL'...
                    ', PRIMARY KEY (SNP)'...
                    ')']);
                
                for k=1:numel(snp_data{1})
                    snp_name = snp_data{1}{k};
                    snp_index = find(strcmp(snp_name,wsc_snps(:,1)),1);
                    if(isempty(snp_index))
                        mym('insert into {S} (SNP, MAJORMAJOR,MAJORMINOR,MINORMINOR,RISKALLELE) values ("{S}","{S}","{S}","{S}","{S}")',tableName,snp_data{1}{k},snp_data{2}{k},snp_data{3}{k},snp_data{4}{k},snp_data{5}{k});
                    else
                        mym('insert into {S} (SNP, gene, chromosome,MAJORMAJOR,MAJORMINOR,MINORMINOR,RISKALLELE) values ("{S}","{S}",{Si},"{S}","{S}","{S}","{S}")',tableName,snp_data{1}{k},wsc_snps{snp_index,2},wsc_snps{snp_index,3},snp_data{2}{k},snp_data{3}{k},snp_data{4}{k},snp_data{5}{k});
                    end
                end
                
                %update - one that was missed in the convertSNPFile2WSCFile as wanted by our SNP paper
                mym('update snp_mapping_t set riskallele="G" where snp="rs12469063"')
                
                mym('select * from {S}',tableName);
                
                mym('close');
            end
        end
    end
    
    methods(Static, Access=private)
        
        
        % ======================================================================
        %> @brief Populates DetectorInfo_T table with manually scored event labels obtained from
        %> WSC .SCO files
        %> @param loadStruct Struct derived from create_Diagnostics_T
        %> @note This is a helper function for create__Diagnostics_T and
        %> is not designed for external use.  
        % =================================================================        
        function loadStruct = scoreRLSsymptoms(loadStruct)
            %code = 9 if unanswered
            %blank is no response for any
            %1,2,3,4,5 for never,yearly,monthly, weekly, daily/nightly
            
            numPatid = numel(loadStruct.patid.value);
            q.S3Q13A =cell2mat(loadStruct.S3Q13A.value);
            q.S3Q13B =cell2mat(loadStruct.S3Q13B.value);
            q.S3Q13D =cell2mat(loadStruct.S3Q13D.value);
            q.S3Q13E =cell2mat(loadStruct.S3Q13E.value);
            
            s.A_monthly_or_more = (q.S3Q13A~=9&q.S3Q13A>=3);
            s.B_monthly_or_more = (q.S3Q13B~=9&q.S3Q13B>=3);
            s.AB_monthly_or_more = s.A_monthly_or_more&s.B_monthly_or_more;
            
            s.A_weekly_or_more = (q.S3Q13A~=9&q.S3Q13A>3);
            s.B_weekly_or_more = (q.S3Q13B~=9&q.S3Q13B>3);
            s.AB_weekly_or_more = s.A_weekly_or_more&s.B_weekly_or_more;
            
            s.A_less_than_monthly = (q.S3Q13A~=9&q.S3Q13A<3);
            s.B_less_than_monthly = (q.S3Q13B~=9&q.S3Q13B<3);
            s.A_less_than_weekly = (q.S3Q13A~=9&q.S3Q13A<=3);
            s.B_less_than_weekly = (q.S3Q13B~=9&q.S3Q13B<=3);
            
            s.D_Yes = q.S3Q13D==1;
            s.D_No = q.S3Q13D==0;
            s.E_Yes = q.S3Q13E==1|q.S3Q13E==2;
            s.E_No = q.S3Q13E==0;
            s.DE_Yes = s.D_Yes&s.E_Yes;
            s.DorE_No = s.D_No|s.E_No;
            
            s.unknown = (s.AB_monthly_or_more&(q.S3Q13D==9|q.S3Q13E==9)); %these people did not answer and should not be in either category...
            s.A_unknown = (s.A_weekly_or_more&(q.S3Q13D==9|q.S3Q13E==9)); %these people did not answer and should not be in either category...
            %RLS broad/monthly
            s.rls_AB_monthly = (s.A_monthly_or_more&s.B_monthly_or_more&s.DE_Yes);%&~s.unknown;
            s.rls_AB_weekly = (s.A_weekly_or_more&s.B_weekly_or_more&s.DE_Yes);%&~s.unknown;
            s.rls_A_weekly = (s.A_weekly_or_more&s.DE_Yes);%&~s.A_unknown;
            
            %Not RLS includes
            s.not_rls_AB_monthly = (s.DorE_No|s.A_less_than_monthly|s.B_less_than_monthly);%&~s.unknown;
            s.not_rls_AB_weekly = (s.DorE_No|s.A_less_than_weekly|s.B_less_than_weekly);%&~s.unknown;
            s.not_rls_A_weekly = (s.DorE_No|s.A_less_than_weekly);%&~s.unknown;
            
            rls_symptom_base_severity = 2;
            
            rls_AB_monthly = NaN(numPatid,1);
            rls_AB_monthly(s.rls_AB_monthly)=1;
            rls_AB_monthly(s.not_rls_AB_monthly)=0;
            loadStruct.rls_ab_monthly.value = mat2cell(rls_AB_monthly,ones(numPatid,1));
            
            rls_AB_monthly_severity = NaN(numPatid,1);
            rls_AB_monthly_severity(s.rls_AB_monthly) = (q.S3Q13A(s.rls_AB_monthly)+q.S3Q13B(s.rls_AB_monthly)-rls_symptom_base_severity*2)/2;
            loadStruct.rls_ab_monthly_severity.value = mat2cell(rls_AB_monthly_severity,ones(numPatid,1));         
            
            rls_A_weekly = NaN(numPatid,1);
            rls_A_weekly(s.rls_A_weekly)=1;
            rls_A_weekly(s.not_rls_A_weekly)=0;
            loadStruct.rls_a_weekly.value = mat2cell(rls_A_weekly,ones(numPatid,1));
            
            rls_A_weekly_severity = NaN(numPatid,1);
            rls_A_weekly_severity(s.rls_A_weekly) = q.S3Q13A(s.rls_A_weekly)-rls_symptom_base_severity;
            loadStruct.rls_a_weekly_severity.value = mat2cell(rls_A_weekly_severity,ones(numPatid,1));
            
            s.A = s.A_weekly_or_more&s.DE_Yes;
            
            s.B = s.A_monthly_or_more&s.D_Yes &~s.A;
            %C is not all
            s.C = (s.A_less_than_monthly&(q.S3Q13B==9|q.S3Q13B<3));
            %D is uncertain
            s.D = q.S3Q13A==9|(q.S3Q13A>3&~s.DE_Yes);
            s.D = (q.S3Q13A==9|isnan(q.S3Q13A)|q.S3Q13D==9)&~s.C;  %40 left D blank; 9 left A blank
            s.F = ~s.B&~s.C&~s.A&~s.D;
            mat2cellConverter = ones(numPatid,1);
            loadStruct.rls_A.value = mat2cell(s.A,mat2cellConverter);
            loadStruct.rls_B.value = mat2cell(s.B,mat2cellConverter);
            loadStruct.rls_C.value = mat2cell(s.C,mat2cellConverter);
            loadStruct.rls_D.value = mat2cell(s.D,mat2cellConverter);
            loadStruct.rls_F.value = mat2cell(s.F,mat2cellConverter);            
        end
        
        %> @brief Returns a database struct for the WSC database.
        %> @retval dbStruct Struct with the fields - name - user - password
        function dbStruct = getDBStruct()
            dbStruct.name = CLASS_WSC_database.dbName;
            dbStruct.user = CLASS_WSC_database.dbUser;
            dbStruct.password = CLASS_WSC_database.dbPassword;
        end        
    end
end

