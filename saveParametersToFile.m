function saveParametersToFile(filename,inputStruct)
%saves all of the fields in inputStruct to a file filename as a .txt file
%written by Hyatt Moore IV sometime during his PhD (2010-2011'ish)
%
%last modified 
%   9/28/2012 - added CHANNELS_CONTAINER.saveSettings() call - removed on
%   9/29/2012
%   7/10/2012 - added batch_process.images field
%   5/7/2012 - added batch_process.database field
%       
global DEFAULTS;
global BATCH_PROCESS;
global PSD;
global MUSIC;
global MARKING;

% global CHANNELS_CONTAINER;

% if(~isempty(CHANNELS_CONTAINER))
%     CHANNELS_CONTAINER.saveSettings();
% end

if(nargin==1)
    paramStruct.PSD = PSD;
    paramStruct.MUSIC = MUSIC;
    
    paramStruct.DEFAULTS = DEFAULTS;
    paramStruct.BATCH_PROCESS.output_files = BATCH_PROCESS.output_files;
    paramStruct.BATCH_PROCESS.output_path = BATCH_PROCESS.output_path;
    paramStruct.BATCH_PROCESS.database = BATCH_PROCESS.database;
    paramStruct.BATCH_PROCESS.images = BATCH_PROCESS.images;
    paramStruct.SEV = MARKING.getSaveParametersStruct();
    
    fid = fopen(filename,'w');
    if(fid<0)
        [path, fname, ext]  = fileparts(filename);
        fid = fopen(fullfile(pwd,[fname,ext]));
    end
    if(fid>0)
        fprintf(fid,'-Last saved: %s\r\n\r\n',datestr(now)); %want to include the '-' sign to prevent this line from getting loaded in the loadFromFile function (i.e. it breaks the regular expression pattern that is used to load everything else).
        
        saveStruct(fid,paramStruct)
        fclose(fid);
    end

%saves all of the fields in inputStruct to a file filename as a .txt file
elseif(nargin==2)
    %     filename = 'sev_parameters.txt';
    % end;
    fnames = fieldnames(inputStruct);
    fid = fopen(filename,'w');
    
    for k=1:numel(fnames)
        fprintf(fid,'%s\t%s\n',fnames{k},num2str(inputStruct.(fnames{k})));
    end;
    
    fclose(fid);
else
    disp('saveParametersToFile requires at least one entry');
end