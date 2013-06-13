function paramStruct = loadParametersFromFile(filename)
%loads a file whose parameters are stored as such per row
%fieldname1 value1
%fieldname2 value2
%....
%an optional ':' is allowed after the fieldname such as
%fieldname: value
%
%The parameters is a structure that contains the listed fields found in the
%file 'filename' along with their corresponding values

% written by Hyatt Moore
% edited: 10.3.2012 - removed unused globals; and changed PSD

global DEFAULTS;
global BATCH_PROCESS;
global PSD;
global MUSIC;

fid = fopen(filename,'r');
paramStruct = loadStruct(fid);
fclose(fid);

PSD = paramStruct.PSD;
DEFAULTS = paramStruct.DEFAULTS;
BATCH_PROCESS = paramStruct.BATCH_PROCESS;
MUSIC = paramStruct.MUSIC;