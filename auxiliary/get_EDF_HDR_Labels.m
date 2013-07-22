function channelNames = get_EDF_HDR_Labels(edf_search_path,edf_search_string)
%channelNames = get_EDF_HDR_Labels(edf_search_path,edf_search_string)
% Obtain channel names from EDFs in the provided search path and optional
% edf_search_string (defaults to *.EDF),
% channel names are stored as a cell of character strings
%

% Hyatt Moore, IV
% < June, 2013

    if(nargin<2)
        edf_search_string = '*.EDF';
        if(nargin<1)
            edf_search_path = pwd;
        end
    end
    
    files = getFilenames(edf_search_path,edf_search_string);
%     files = dir('*.EDF');
    channelNames = {};
    for f=1:numel(files)
        %         filename = fullfile(edf_path,files(f).name);
        filename = fullfile(edf_search_path,files{f});
        HDR = loadEDF(filename);
        channelNames = union(channelNames,HDR.label);
    end
    disp(char(channelNames));
end