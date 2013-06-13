function [filenames,fullfilenames] = getFilenames(pathname,ext)
% function [filenames,fullfilenames] = getFilenames(pathname,ext)
%  pathname is a string of the folder to search
%  [filenames] = getFilenames(pwd,'*.m');
%      filenames contains the filenames with .m extension in the current
%      directory
% copyright Hyatt Moore IV

if(nargin<2)
    ext = '';
end
dirPull = dir(fullfile(pathname,ext));
directory_flag = cells2mat(dirPull.isdir);
names = cells2cell(dirPull.name);
filenames = names(~directory_flag);
if(nargout>1)
    fullfilenames = cell(size(filenames));
    for k=1:numel(filenames)
        fullfilenames{k} = fullfile(pathname,filenames{k});
    end
end
end

