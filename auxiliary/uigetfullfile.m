%a wrapper for matlab's uigetfile - this one returns the fullfilename; not
%as a path and a filename, or empty if the user cancels or it does not
%exist.
function fullfilename = uigetfullfile(filter_cell,display_message,multiselect_option)

if(nargin<3 || (~strcmpi(multiselect_option,'on') || ~strcmpi(multiselect_option,'off')))
    [filename, pathname, ~] = uigetfile(filter_cell,display_message);
else
    [filename, pathname, ~] = uigetfile(filter_cell,display_message,'MultiSelect',multiselect_option);    
end

if(isnumeric(filename) && ~filename)
    fullfilename = [];
else
    fullfilename = fullfile(pathname,filename);
end
if(~exist(fullfilename,'file'))
    fullfilename = [];
end

end
