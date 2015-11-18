function fs = getSamplerateDlg(defaultSamplerate)
    if(nargin<1 || isempty(defaultSamplerate))
        defaultSamplerate = {'100'};
    end
    name = 'Sampling frequency';
    numLines = 1;
    fsStr = inputdlg('Enter sampling rate of data file',name,numLines,defaultSamplerate);
    if(~isempty(fsStr) && iscell(fsStr))
        fs = str2double(fsStr{1});
    else
        fs = 0;
    end
end