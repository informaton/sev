function filenames = getPathnames(path)
%filenames = getPathnames(path)
% 
% directory wrapper to get just filenames in the given directory

%Hyatt Moore, IV (< June, 2013)
    dirPull = dir(fullfile(path));
    directory_flag = cells2mat(dirPull.isdir);
    names = cells2cell(dirPull.name);
    filenames = names(directory_flag);
end 

