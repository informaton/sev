function pstruct = loadStruct(fid,pstruct)
%pstruct = loadStruct(fid,{pstruct})
%loadStruct will parse the file with file identifier fid to find structure
%and substructure value pairs.  If pstruct is passed as an input argument
%then the file substructure and value pairings will be put into it as new
%or overwriting fields and subfields.  If pstruct is not included then a
%new/original structure is created and returned.
%fid must be open for this to work.  fid is not
%closed at the end of this function.  

% Hyatt Moore IV (< June, 2013)

% ferror(fid,'clear');
% status = fseek(fid,0,'bof'); %move to the beginning of file
% ferror(fid);

file_open = true;

% pat = '\.?([^\.\s])+|$\s+(.*)$';

%I think this will actually work better here...in case of non structure
%type fields that have been setup
% pat = '([^\.\s])+\.|$([\s])+\s+(.*)';
pat = '^([^\.\s]+)|\.([^\.\s]+)|\s+(.*)+$';


% pat = '([^\.\s]+)([^\.\s]+)*\s+([^\s\.])+';

% pat = '([^\s])$';

% pat = '([^\.\s])+\.|$([^\.\s]+)\s+([^\.\s]+)';
% pat = '^([^\.\s])+\.|$([^\.\s]+)\s+([^\.\s]+)';
% 
% 
% pat = '([^\.\s]+)\s+([^\.\s]+)';
% 
if(nargin<2)
    pstruct = struct;
end;

while(file_open)
    curline = fgetl(fid);
    if(~ischar(curline))
        file_open = false;
    else
        tok = regexp(curline,pat,'tokens');
        if(~isempty(tok))
            pstruct = tokens2struct(pstruct,tok);
        end
    end;
end;


function pstruct = tokens2struct(pstruct,tok)
%helper function for loadStruct
%pstruct is the parent struct by which the tok cell will be converted to
%tok is a cell array - the last cell is the value to be assigned while the
%previous cells are increasing nestings of the structure (i.e. tok{1} is
%the highest parent structure, tok{2} is the substructure of tok{1} and so
%and on and so forth until tok{end-1}.  tok{end} is the value to be
%assigned.
%the tok structure is added as a child to the parent pstruct.  

if(numel(tok)>1 && isvarname(tok{1}{:}))
    
    fields = '';
    
    for k=1:numel(tok)-1
        fields = [fields '.' tok{k}{:}];
    end;
    
%     if(isempty(str2num(tok{end}{:})))
    if(isnan(str2double(tok{end}{:})))
        evalmsg = ['pstruct' fields '=tok{end}{:};'];
    else
        evalmsg = ['pstruct' fields '=str2double(tok{end}{:});'];
    end;

    eval(evalmsg);
end;



%some notes on the thought process to developing this solution.
% str = 'artifact_dlg.eeg.rms_short 30'

%these did not work at all
% pat = '^(?<root>[^\s\.]+)(\.(?<fields>[^\s\.]+))*(:?)\s(?<value>.+)$'
% pat = '(?<fields>[^\s\.]+)\.)*(:?)\s(?<value>.+)'
% pat = '(?<fields>[^\s\.]+\.)+\s(?<value>.+)'
% 
%these worked but did not give the desired results 
% pat = '(?<root>[^\s\.]+)(\.(?<fields>[^\s\.]+))*(:?)\s(?<value>.+)'
% pat = '(?<fields>[^\s\.]+\.)*(:?)\s(?<value>.+)'
% pat = '(?<fields>[^\s\.]+\.)*(?<lastfield>[^\s\.]+)\s(?<value>.+)'
% pat = '(?<fields>[^\s\.]+\.)*(?<lastfield>[^\s\.]+)\s(?<value>.+)$'
% pat = '((?<fields>[^\s\.]+)\.)*(?<lastfield>[^\s\.]+)\s(?<value>.+)$'
% pat = '(?<fields>[^\s\.]+)\.'
% pat = '(?<fields>[^\s\.]+)\.(?<lastfield>[^\s\.]+)'
% 
% v=regexp(str,'([^\.])+(\.([^\.]+))*\s(.+)','tokens')
% 
% v=regexp(str,'\.?([^\.\s])+|\s(.*)','tokens')
% v=regexp(str,'\.?(?<field>[^\.\s])+|\s(?<value>.*)','tokens') <--- use this one...
% v=regexp(str,'\.?(?<field>[^\.\s])+|\s(?<value>.*)','names')
% v=regexp(str,'\.?(?<field>[^\.\s])+|\s(?<value>.*)$','names')
% 
% %this was from inside the original sev.m implementation
% parameters = loadParametersFromFile(handles.user.parameters_filename);
%     if(~isempty(parameters))
%         fnames = fieldnames(parameters);
%         
%         %possible security risk here ...
%         for k=1:numel(fnames)
%             %this check is necessary since some parameters are numeric, but I don't
%             %want to check for their type each time...
%             if(isstruct(parameters.(fnames{k})))
%                 tmpField = fieldnames(parameters.(fnames{k}));
%                 for k2=1:numel(tmpField)
%                     if(isempty(str2num(parameters.(fnames{k}).(tmpField{k2}))))
%                         handles.user.(fnames{k}).(tmpField{k2})=parameters.(fnames{k}).(tmpField{k2}); %it's text, so leave it alone
%                     else
%                         handles.user.(fnames{k}).(tmpField{k2})=str2num(parameters.(fnames{k}).(tmpField{k2}));
%                     end;
%                 end;
%             else
%                 if(isempty(str2num(parameters.(fnames{k}))))
%                     handles.user.(fnames{k})=parameters.(fnames{k}); %it's text, so leave it alone
%                 else
%                     handles.user.(fnames{k})=str2num(parameters.(fnames{k}));
%                 end;
%             end;
%         end;
%     end;
