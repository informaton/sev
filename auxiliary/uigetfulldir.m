%a wrapper for matlab's uigetdir - this one returns the directory pathname
%or empty if the user cancels or it does not exist.
function directoryname = uigetfulldir(initialDirectoryname,displayMessage)

    directoryname = uigetfile(initialDirectoryname,displayMessage);
    
    if(isnumeric(directoryname))
        directoryname = [];
    end
    if(~exist(directoryname,'dir'))
        directoryname = [];
    end
end
