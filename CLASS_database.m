%> @file CLASS_database.m
%> @brief Database development and interaction class.
% ======================================================================
%> @brief The class is designed for baseline database development, functionality, and 
%> interaction.
%> @note: A MySQL database must be installed on the local host for class
%> instantiations to operate correctly.
%> @note Here are a few tips for upgrading MySQL on a Mac
%> - Turn off MySQL server and install new MySQL (which you should have
%> downloaded from apache's website)
%> - After installation, copy the database files from the old mysql/data
%> directory to the new mysql/data directory (i.e.
%> /usr/local/mysql_blah_blah_old_Version/data/[database_name] to
%> /usr/local/mysql/data/ folder.
%> - Open a terminal window in Mac and change directory to the mysql data
%>  folder like so:
%> - cd /usr/local/mysql/data
%> - Then for each databasse that you transferred over, give _mysql
%> permission to access it (and not just yourself)
%> If you transferred a database named 'CManager_DB' for example then you
%> would type this into the terminal:
%> - sudo chown _mysql CManager_DB
%> - Do this for each database file that you copied over.  
%> - Grant user privileges to these databases (that you just moved) again.
%> These are lost in the upgrade.  In MySQL use a "Grant all on [database
%> name].* to [username]@localhost identified by [password].  Otherwise,
%> from MATLAB, run the CLASS_database instance method 'addUser()'.
%> Copy all innodb tables from the old mysql/data directory to the new one
%>  (e.g. ib_logfile0, ib_logfile1, and ibdata).  
%> From the terminal run, mysql_upgrade
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
        createDBandTables(obj)
    end
    
    methods
        % ======================================================================
        %> @brief Open the database associated with the
        %> derived class.
        %> @param obj CLASS_database derivded instance.
        % =================================================================
        function open(obj)
            obj.openDB(obj.dbStruct);
        end  
        
        % ======================================================================
        %> @brief Adds a table column to the database associated with the
        %> instantiated class.
        %> @param obj CLASS_database derivded instance.
        %> @param obj tableName MySQL table to add a column to
        %> @param obj fieldName Name of the column to add to tableName
        %> @param obj fieldDefintion Definition of column being added.      
        %> @note For example:
        %> @note obj = CLASS_CManager_database();
        %> @note obj.addTableField('cohortinfo_t','dockingFolder','varchar(128)');
        % =================================================================
        function addTableField(obj,tableName,fieldName, fieldDefinition)
            obj.openDB(obj.dbStruct);
            
            mym(sprintf('alter table %s add column %s %s',tableName,fieldName,fieldDefinition));
            % This fails on some types of work
            % mym('alter table {S} add column {S} {S}',tableName,fieldName,fieldDefinition); 
            
        end        
        
        % ======================================================================
        %> @brief Rename a table column in the database associated with the
        %> instantiated class.
        %> @param obj CLASS_database derivded instance.
        %> @param obj tableName MySQL table to add a column to
        %> @param obj oldFieldName Name of the column to change from.
        %> @param obj newFieldName New name to change the column to.
        %> @note For example:
        %> @note obj = CLASS_CManager_database();
        %> @note obj.renameField('cohortinfo_t','dockingFolder','docking_foldername');
        % =================================================================
        function renameField(obj,tableName,oldFieldName, newFieldName)
            obj.openDB(obj.dbStruct);
            
            %retrieve the original column definition
            x=mym('show columns from {S} where Field = "{S}"',tableName,oldFieldName);
            if(~isempty(x) && iscell(x.Type))
                colDef = char(x.Type{1}(:)');           %use char() b/c mysql can store as uint8's.
                mym(sprintf('alter table %s change column %s %s %s',tableName,oldFieldName,newFieldName,colDef));               
            else
               fprintf(1,'An error occurred trying to rename column %s from %s\n',oldFieldName,tableName); 
            end                
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
        
        % ======================================================================
        %> @brief Performs a system level MySQL dump of the identified
        %> table to a file with '.sql' extension.
        %> @param obj Instance of CLASS_database
        %> @param tableName Name of the table (as a string) which will be
        %> dumped as a MySQL file dump.
        % ======================================================================
        function dumpTable(obj,tableName)
            dumpFilename = fullfile(pwd,strcat(tableName,'.sql'));
            system(sprintf('mysqldump -u%s -p%s %s %s > %s',obj.dbUser,obj.dbPassword,obj.dbName,tableName,dumpFilename),'-echo');
        end
        
        % ======================================================================
        %> @brief Performs a system level mysqldump call to import the
        %> passed sql dump file.
        %> @param obj Instance of CLASS_database
        %> @param sqlDumFile File name of the mysql dump to import (i.e. a .sql file)
        % ======================================================================
        function importTable(obj,sqlDumpFile)
            system(sprintf('mysql -u%s -p%s %s < %s',obj.dbUser,obj.dbPassword,obj.dbName,sqlDumpFile),'-echo');
        end

        % ======================================================================
        %> @brief Adds the user specified in the dbStruct instance variable to the
        %> the database (also specified in dbStruct)
        %> @param obj Instance of CLASS_database
        % ======================================================================
        function addUser(obj)
           
            mym('open','localhost','root')            
            %setup a user for this person
            CLASS_database.grantPrivileges(obj.dbStruct);
            mym('close');
        end
        
            
        
        
    end
    
    methods(Static)
        
        % ======================================================================
        %> @brief Closes the current MySQL connection
        % ======================================================================        
        function close()
            mym('close');
        end
        
        
        % ======================================================================
        %> @brief Helper function for opening the MySQL database using field values
        %> provided in dbStruct.
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
        %> @brief Adds the user specified in the dbStruct instance variable to the
        %> the database (also specified in dbStruct)%> @param dbStruct A structure containing database accessor fields:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        function grantPrivileges(dbStruct)
            mym(['GRANT ALL ON ',dbStruct.name,'.* TO ''',dbStruct.user,'''@''localhost'' IDENTIFIED BY ''',dbStruct.password,'''']);
        end
        
        
        % ======================================================================
        %> @brief Refactors a table's patstudykey using another field that is listed in the studyinfo_t
        %> table (e.g. patid).
        %> @param obj Instance of CLASS_database
        %> @param table2refactor Table name whose patstudykey is to be refactored
        %> @param fieldToRefactorAgainst The field which is used as an
        %> alternate key into the studyinfo_t which also identifies a uninque
        %> record in the table2refactor table.
        %> @note *patid* is the default value for field2RefactorAgainst
        %> @note A connection must already exist and be open before
        %> refactorPatstudykey is invoked.
        % ======================================================================
        function refactorPatstudykey(table2Refactor, field2RefactorWith)
            if(mym)
                fprintf(1,'An mym connection must be open!  Try calling openDB() or open() using your CLASS_database based object.\n\n');
            end

            if(~strcmpi(table2Refactor,'studyinfo_t'))
                if(nargin<3 || isempty(field2RefactorWith))
                    field2RefactorWith = 'patid';
                end
                    
                mym('update {S} inner join studyinfo_t on ({S}.{S} = studyinfo_t.{S}) set {S}.{S} = studyinfo_t.{S}',table2Refactor,table2Refactor,field2RefactorWith,field2RefactorWith,table2Refactor,field2RefactorWith,field2RefactorWith);
            else
                fprintf(1,'Cannot refactor with the studyinfo_t as your source table!\n');
            end
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
        %> @brief MySQL helper function.  Updates fields values for the specified
        %> table of the currently open database.  This is a wrapper for the
        %> the mysql call UPDATE table_name SET field1=new-value1, field2=new-value2
        %> [WHERE Clause]
        %> @param tableName Name of the table to updated (string)        
        %> @param fields Cell of column label(s) (strings)
        %> @param values Cell of column values that correspond to fields' column labeling.
        %> @param whereStmt The 'where' clause (sans 'where'), which must be included (string)
        %> @note executes the mysql statement
        %> <i>UPDATE tableName SET fields{1}=values{1}[, fields{k}=values{k}] WHERE whereStmt</i>
        %> Example: 
        %>      x = CLASS_CManager_database
        %>      x.open();
        %>      x.updateTableEntry('cohortinfo_t',{'dockingFolder','src_foldertype'},{'"/Volumes/BUFFALO 500/dock"','"flat"'},'cohortID=1');
        %> - x.updateTable('cohortinfo_t','src_foldername','"/Volumes/BUFFALO 500/WSC"','cohortID=1');
        %> results in the following mysql statement:
        %> - update cohortinfo_t set  src_foldername="/Volumes/BUFFALO
        %> 500/WSC" WHERE cohortID=1 and src_psg_filename="A0097_4 174733.EDF"')
        function updateTableEntry(tableName, fields, values, whereStmt)
            %UPDATE table_name SET field1=new-value1, field2=new-value2
            %[WHERE Clause]
            if(~iscell(fields))
                fields = {fields};
            end
            if(~iscell(values))
                values = {values};
            end
            if(iscell(whereStmt))
                whereStmt = whereStmt{1};
            end

            updateStr = sprintf('update %s set ',tableName);
            
            %generate the column=value portion.
            for k=1:numel(fields)
                value = values{k};
                if(isnumeric(value))
                    value = num2str(value);
                end
                updateStr = sprintf('%s %s=%s,',updateStr,fields{k},value);
            end
            updateStr(end)=[]; %remove the trailing ',' 
            updateStr = sprintf('%s WHERE %s',updateStr,whereStmt);
            
            mym(updateStr);
        end
                
        % ======================================================================
        %> @brief MySQL helper function.  Delete a table entry or entries
        %> from the specified table of the current database which match the 
        %> the where statement provided.  This is a wrapper for the
        %> the mysql call DELETE FROM table_name WHERE whereStmt
        %> @param tableName Name of the table to updated (string)        
        %> @param whereStmt The 'where' clause (sans 'where'), which must be included (string)
        %> @note executes the mysql statement
        %> <i>DELETE FROM tableName WHERE whereStmt</i>
        %> Example: 
        %>      x = CLASS_CManager_database
        %>      x.open();
        %>      x.deleteTableEntry('filestudyinfo_t','cohortID=1 and src_psg_filename="A0097_4 174733.EDF"');
        %> results in the following mysql statement:
        %> - delete from filestudyinfo_t where cohortID=1 and
        %src_psg_filename="A0097_4 174733.EDF"
        function deleteTableEntry(tableName, whereStmt)
            deleteStr = sprintf('delete from %s WHERE %s',tableName,whereStmt);
            
            mym(deleteStr);
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
        %> @brief Retrieves cohort descriptor data as a struct from
        %> the .inf filename provided.
        %> @param inf_filename Full filename (i.e. path included) of either a text
        %> file containing cohort descriptor data as tab-delimited entries
        %> or an XML formatted file (with .xml extension). 
        %> @retval cohortSstruct A structure containing file value pairings
        %> For example, database accessor fields for a database.inf file would be:
        %> @li @c name Name of the database to use (string)
        %> @li @c user Database user (string)
        %> @li @c password Password for @c user (string)
        function cohortStruct = loadCohortStruct(struct_filename)
            %Hyatt Moore, IV (< June, 2013)
            cohortStruct = [];
            if(exist(struct_filename,'file'))
                [~,~,ext] = fileparts(struct_filename);
                if(strcmpi(ext,'xml'))
                    cohortStruct = CLASS_settings.loadXMLstruct(struct_filename);
                    
                else
                    fid = fopen(struct_filename,'r');
                    cohortStruct = CLASS_settings.loadStruct(fid);
                    fclose(fid);
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
        
        
        % ======================================================================
        %> @brief Exports the output of a mysql query to a file.
        %> @param query A mysql query (string)
        %> @param filename The filename to save the MySQL results to
        %> (string).
        %> @param optional_delim Delimeter to separate each row's results
        %> by (optional).  For example, ',' would separate using a comma.
        %> The default is to use a tab-delimiter (i.e. '\t').
        % =================================================================
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

