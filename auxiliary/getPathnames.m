%filenames = getPathnames(path)
% 
% directory wrapper to get names of any subdirectories contained in pathname (i.e. a directory)
function [pathnames, fullpathnames] = getPathnames(srcPathname)

%Hyatt Moore, IV (< June, 2013)
    dirPull = dir(fullfile(srcPathname));
    directory_flag = cells2mat(dirPull.isdir);
    names = cells2cell(dirPull.name);
    pathnames = names(directory_flag);
    unused_dir = strncmp(pathnames,'.',1)|strncmp(pathnames,'..',2);
    if(~isempty(unused_dir))
        pathnames(unused_dir) = [];
    end
    if(nargout>1)
        fullpathnames = cell(size(pathnames));
        for f=1:numel(fullpathnames)
            fullpathnames{f} = fullfile(srcPathname, pathnames{f});
        end
    end
end 

