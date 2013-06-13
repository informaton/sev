function string = makeWhereInString(data,dataType)
%------------------------------------------------------------
% string = makeWhereInString(data,dataType)
%
% helpfer function to return the vector or cell as a string for
% use in a mysql 'where somefield in (string) ' select query
%
% dataType can be 'numeric' or 'string'
%
%------------------------------------------------------------

% Hyatt Moore, IV (< June, 2013)

if(isempty(data))
    string = '';
else
    if(strcmp(dataType,'string'))
        strfmt = '"%s"';
        string = sprintf(strfmt,data{1});
    else
        strfmt = '%f';
        if(~isnumeric(data))
            data = str2num(data);
        end
        string = sprintf(strfmt,data(1));
    end
    
    strfmt = ['%s,',strfmt];
    
    if(iscell(data))
        for k=2:numel(data)
            string = sprintf(strfmt,string,data{k});
        end
    else
        for k=2:numel(data)
            string = sprintf(strfmt,string,data(k));
        end
    end;
end
string=['(',string,')'];
