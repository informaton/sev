%> @file CLASS_CManager_database.m
%> @brief Database development class for managing and organizing data from 
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
        
        
        function createDBandTables(obj)
            obj.create_DB();
        end
        
        function updateDBandTables(obj)
            
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

