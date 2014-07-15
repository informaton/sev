%> @file CLASS_SSC_database.m
%> @brief Database development class for Stanford Sleep Cohort data.
% ======================================================================
%> @brief The class is designed for database development, functionality, and 
%> interaction with SEV and Stanford Sleep Cohort data.
%> @note: A MySQL database must be installed on the local host for class
%> instantiations to operate correctly.
%>
% ======================================================================
classdef CLASS_SSC_database < CLASS_database_psg

    properties (Constant)
        %> Database name
        dbName = 'SSC_DB';
        %> Database user name        
        dbUser = 'SSC_user';
        %> Database user password        
        dbPassword = 'SSC_password';
    end
    properties
    end
    
    methods
        %> @brief Class constructor.
        %> @retval obj Instance of CLASS_SSC_database.
        function obj = CLASS_SSC_database()
            obj.dbStruct = CLASS_SSC_database.getDBStruct();
        end
        
        % ======== ABSTRACT implementations for SSC_database =========
        % ======================================================================
        %> @brief Create a mysql database and tables for the Stanford
        %> sleep Cohort.  First creates SSC Database and GRANTs access to ssc_user
        %> and then CREATEs the following tables:
        %> @li  StudyInfo_T
        %> @li  SSC_Diagnostics_T
        %> @li  StageStats_T
        %> @param obj Instance of CLASS_SSC_database
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
            
            % make the database for the SSC
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
            obj.populate_StudyInfo_T(obj.dbStruct,EDF_pathname,'Embla');           
            obj.open();mym('describe studyinfo_t');           
            
            obj.create_DetectorInfo_T(obj.dbStruct);
            obj.populate_SCO_DetectorInfo_T(obj.dbStruct);
            obj.open();mym('describe detectorinfo_t');
            
            %             obj.create_Diagnostics_T(pwd);
            obj.create_Diagnostics_T_from_file();
            obj.open();mym('describe diagnostics_t');
            
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
        end       
        
        % ======================================================================
        %> @brief This builds the Diagnostics table for the Stanford Sleep Cohort using a
        %> .txt file created with Emmanuel after first outputting the diagnostics_t
        %> table as created with create_SSC_Diagnostics_T.m
        %> The created table Diagnostics_T is added to the SSC_DB database.  Any previously existing
        %> table with the same name is first dropped.        
        %> @note  The created table Diagnostics_T is added to the SSC_DB database.  Any previously existing
        %> table with the same name is first dropped.
        % =================================================================
        function create_Diagnostics_T_from_file(obj,ssc_filename)
            %
            % Author: Hyatt Moore IV
            % created 11/13/12
            
            %create the table now for the first time
            if(nargin==1 || isempty(ssc_filename))
                msg = 'Select ssc_DiagnosticsEM.xls file';
                [ssc_filename, pathname, ~] = uigetfile({'ssc_DiagnosticsEM.xls','Diagnostic input file';'*.xls','Excel worksheets (*.xls)'},msg,'MultiSelect','off');
                
                if(isnumeric(ssc_filename) && ~ssc_filename)
                    ssc_filename = [];
                else
                    ssc_filename = fullfile(pathname,ssc_filename);
                end
            end
            
            if(~isempty(ssc_filename))
                try
                    [~,~,raw] =xlsread(ssc_filename);
                    data = raw;
                    hdr = raw(1,:);
                    
                    column_names = lower(hdr);
                    ext_exp = '^.*_(?<type>[a-zA-Z]+)';
                    exp = regexp(column_names,ext_exp,'names');
                catch me
                    showME(me);
                end

            end
                
            
            tableName = 'diagnostics_t';
            
            %table create string
            TStr = sprintf('CREATE TABLE IF NOT EXISTS %s (',tableName);
            try
                for n=1:numel(column_names)
                    name = column_names{n};
                    if(isempty(exp{n}))
                        col_type = '';
                    else
                        col_type = exp{n}.type;
                    end
                    
                    if(~strcmpi(col_type,'ignore'))
                        switch col_type
                            case {'flag','bool'}
                                column.(name).table_format = 'bool default null';
                                column.(name).sprint_format = '%u';
                            case {'float','pct','index'}
                                column.(name).table_format = 'DECIMAL (6,3) UNSIGNED DEFAULT NULL';
                                column.(name).sprint_format = '%0.3f';
                                
                            case 'string'
                                column.(name).table_format = 'VARCHAR(100) default null';
                                column.(name).sprint_format = '%s';
                            case 'date'
                                column.(name).table_format = 'DATE';
                                column.(name).sprint_format = '%s';
                            case 'smallint'
                                column.(name).table_format = 'SMALLINT UNSIGNED DEFAULT NULL';
                                column.(name).sprint_format = '%u';
                            otherwise
                                if(strcmpi(name,'gender'))
                                    column.(name).table_format = 'ENUM(''M'',''F'') DEFAULT NULL';
                                    column.(name).sprint_format = '"%c"';
                                else
                                    column.(name).table_format = 'SMALLINT UNSIGNED DEFAULT NULL';
                                    column.(name).sprint_format = '%u';
                                end
                        end
                        TStr = sprintf('%s %s %s,',TStr,name,column.(name).table_format);
                    else
                        disp([name,' ignored']);
                    end
                end
                
            catch me
                
                disp(me.message);
                me.stack
            end
            
            TStr = sprintf('%s PRIMARY KEY (PATSTUDYKEY))',TStr);
            
            
            obj.open();
            mym(['DROP TABLE IF EXISTS ',tableName]);
            mym(TStr);
            ssc_txt_filename = strrep(ssc_filename,'xls','txt');
                
            if(ispc)
                ssc_txt_filename(ssc_txt_filename=='\') = '/';
            end
            loadStr = sprintf('load data local infile "%s" into table %s LINES TERMINATED BY "\r" ignore 1 lines %s',ssc_txt_filename,tableName,strrep(makeWhereInString(column_names,'string'),'"',''));
            mym(loadStr);
            mym('select * from diagnostics_t');
            
        end
        
        % ======================================================================
        %> @brief Creates Diagnostic_T table for the SSC database and populates it 
        %> from the SSC datashseet file provided by Stanford Sleep Cohort.
        %> @param obj Instance of CLASS_SSC_database
        %> @param diagnostics_xls_filename File name of .xls file with SSC subject information
        %> to populate Diagnostic_T table with (string).
        %> @note  The created table Diagnostics_T is added to the SSC_DB database.  Any previously existing
        %> table with the same name is first dropped.
        % =================================================================
        function create_Diagnostics_T(obj, path_with_diagnostics_xls_file)
            % this builds the Diagnostics table for the Stanford Sleep Cohort
            % The created table Diagnostics_T is added to the SSC_DB database.  Any previously existing
            % table with the same name is first dropped.
            %
            % Author: Hyatt Moore IV
            % created 10/25/12
            obj.open();
            
            if(nargin<2 || isempty(path_with_diagnostics_xls_file))
                msg = 'Select directory with SSC diagnostic .xls files (blood_work, psg_study_1, doctor_notes)';
                disp(msg);
                path_with_diagnostics_xls_file =uigetdir(pwd,msg);
                if(isnumeric(path_with_diagnostics_xls_file) && ~path_with_diagnostics_xls_file)
                    path_with_diagnostics_xls_file = [];
                end
                
            end
            if(~isempty(path_with_diagnostics_xls_file))
                
                worksheets = {'demographics','blood_work','psg_study_1','doctor_notes'};
                hdr = {};
                for w=1:numel(worksheets)
                    sheet = worksheets{w};
                    ssc_filename = fullfile(path_with_diagnostics_xls_file,strcat('ssc_data_',sheet,'.xls'));
                    
                    [~,~,raw] =xlsread(ssc_filename);
                    data.(sheet) = raw;
                    hdr = [hdr{:},raw(1,:)];
                end
                
                column_names = lower(unique(hdr));
                ext_exp = '^.*_(?<type>[a-zA-Z]+)';
                exp = regexp(column_names,ext_exp,'names');
                
                
                
                tableName = 'diagnostics_t';
                
                %table create string
                TStr = sprintf('CREATE TABLE IF NOT EXISTS %s (patstudykey smallint unsigned not null, patid char(4) not null, studynum tinyint unsigned default 1, visitsequence tinyint unsigned default 1,',tableName);
                try
                    for n=1:numel(column_names)
                        name = column_names{n};
                        if(isempty(exp{n}))
                            col_type = '';
                        else
                            col_type = exp{n}.type;
                        end
                        
                        if(~strcmpi(col_type,'ignore'))
                            switch col_type
                                case {'flag','bool'}
                                    column.(name).table_format = 'bool default null';
                                    column.(name).sprint_format = '%u';
                                case {'float','pct','index'}
                                    column.(name).table_format = 'DECIMAL (6,3) UNSIGNED DEFAULT NULL';
                                    column.(name).sprint_format = '%0.3f';
                                    
                                case 'string'
                                    column.(name).table_format = 'VARCHAR(100) default null';
                                    column.(name).sprint_format = '%s';
                                case 'date'
                                    column.(name).table_format = 'DATE';
                                    column.(name).sprint_format = '%s';
                                case 'smallint'
                                    column.(name).table_format = 'SMALLINT UNSIGNED DEFAULT NULL';
                                    column.(name).sprint_format = '%u';
                                otherwise
                                    if(strcmpi(name,'gender'))
                                        column.(name).table_format = 'ENUM(''M'',''F'') DEFAULT NULL';
                                        column.(name).sprint_format = '"%c"';
                                    else
                                        column.(name).table_format = 'SMALLINT UNSIGNED DEFAULT NULL';
                                        column.(name).sprint_format = '%u';
                                    end
                            end
                            TStr = sprintf('%s %s %s,',TStr,name,column.(name).table_format);
                        else
                            disp([name,' ignored']);
                        end
                    end
                    
                catch me
                    showME(me);
                end
                
                TStr = sprintf('%s PRIMARY KEY (PATSTUDYKEY))',TStr);
                disp(TStr);
                mym(TStr);
                
                openDB(dbStruct);
                mym(['DROP TABLE IF EXISTS ',tableName]);
                mym(TStr);
                
                %Excel stores dates as the number of days elapsed from 1/1/1900 - where
                %this date has a value of 00001.  And I need to subtract 2, in order to get
                %the correct date entered.
                excel_pivot_year=datenum('01.01.1900','mm.dd.yyyy')-2;
                
                studynum = 1; %the default here for all ssc studies at the moment
                for w=1:numel(worksheets)
                    sheet = worksheets{w};
                    %obtain the hdr row and find out where the unique column names are
                    %located in the header
                    hdr_names = lower(data.(sheet)(1,:));
                    [matched_names,column_name_indices,hdr_name_indices] = intersect(column_names,hdr_names);
                    
                    columnStr = 'patstudykey,patid,studynum,visitsequence'; % keep track of the columns I will be adding into one at a time...
                    
                    for m=1:numel(hdr_name_indices)
                        hdr_index = hdr_name_indices(m);
                        name = hdr_names{hdr_index};
                        column.(name).values = data.(sheet)(2:end,hdr_index);
                        columnStr = sprintf('%s,%s',columnStr,name);
                    end
                    for k=1:numel(column.dbid.values)
                        patid = num2str(column.dbid.values{k},'%.4u');
                        q = mym('select patstudykey, visitsequence from studyinfo_t where patid="{S}" and studynum={Si}',patid,studynum);
                        
                        if(~isempty(q.patstudykey))
                            
                            valuesStr = sprintf('%u,%s,%u,%u',q.patstudykey,patid,studynum,q.visitsequence);
                            updateColumnStr ='';
                            for n=1:numel(matched_names)
                                
                                %                 if(k==903 && strcmpi(sheet,'doctor_notes') && n>15)
                                %                    disp('stop here');
                                %                 end
                                name = matched_names{n};
                                value = column.(name).values{k};
                                fmt = column.(name).sprint_format;
                                if(isempty(value)||any(isnan(value)))
                                    value = 'NULL';
                                    fmt = '%s';
                                elseif(strcmpi(column.(name).table_format,'date'))
                                    try
                                        if(ischar(value))
                                            value = datestr(datenum(value,'mm/dd/yyyy'),'"yyyy-mm-dd"');
                                        elseif(isnumeric(value))
                                            value = ['"',datestr(value+excel_pivot_year,'yyyy-mm-dd'),'"'];
                                        end
                                    catch me
                                        me
                                    end
                                    
                                elseif(strcmpi(column.(name).table_format,'VARCHAR(100) default null'))
                                    value = deblank(value);
                                    if(isempty(value))
                                        value = 'NULL';
                                    else
                                        value = ['"',strrep(value,'"',''''),'"'];
                                    end
                                elseif(strcmpi(column.(name).table_format,'bool default null'))
                                    if(strcmp(value,'.')||strcmpi(value,'false'))
                                        value = 0;
                                    elseif(strcmpi(value,'true'))
                                        value = 1;
                                    end
                                end
                                
                                valuesStr = sprintf(['%s,',fmt],valuesStr,value);
                                updateColumnStr = sprintf(['%s,%s=',fmt],updateColumnStr,name,value);
                            end
                            try
                                updateColumnStr(1) = ''; %remove leading comman
                                mym(sprintf('insert into diagnostics_t (%s) values (%s) on duplicate key update %s',columnStr,valuesStr,updateColumnStr));
                                %                 (fprintf(1,'insert into diagnostics_t (%s) values (%s)',columnStr,valuesStr));
                                
                            catch me
                                me.stack
                                me.message
                                disp(me);
                            end
                            
                        else
                            disp([patid,' does not exist']);
                        end
                    end
                end
            else
                fprintf('No files were entered or found.  The diagnostics_t table was not created.\n');
            end            
        end
    end
    
    %> @brief Open a mysql connection to the SSC database.
    methods(Static)
        function staticOpen()
            CLASS_database.close();
            CLASS_database.openDB(CLASS_SSC_database.getDBStruct);
        end
    end
    
    methods(Static, Access=private)
        %> @brief Returns a database struct for the SSC database.
        %> @retval dbStruct Struct with the fields - name - user - password
        function dbStruct = getDBStruct()
            dbStruct.name = CLASS_SSC_database.dbName;
            dbStruct.user = CLASS_SSC_database.dbUser;
            dbStruct.password = CLASS_SSC_database.dbPassword;
        end 
    end
end

