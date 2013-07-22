function openDB(dbStruct)
% function openDB(dbStruct)
% Database help function for opening the MySQL database using field values
% of dbStruct, a struct with the fields:
%   .user   - user name
%   .password  - user password
%   .name   - database name
%

% Hyatt Moore, IV (< June, 2013)

    mym('close');
    mym('open','localhost',dbStruct.user,dbStruct.password);
    mym(['USE ',dbStruct.name]);                   