function database_struct = loadDatabaseStructFromInf(inf_filename,optional_choice)
%database_struct = loadDatabaseStructFromInf(inf_filename,optional_choice)
%
%database_struct contains fileds 'name','user','password' for interacting with a mysql database
%optional choice can be provided to return just one database
%preference set when multiple database entries are present in
%the supplied inf_filename.

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