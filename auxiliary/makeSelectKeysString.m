function selectStr = makeSelectKeysString(cellOfKeys)
%------------------------------------------------------------
% string = makeSelectKeysString(cellString)
%
% example:  
%    cellString = {'A0001';
%                  'A0003';
%                  'A0008'};
%
%    selectStr = makeSelectKeysString(cellString)
%
%    ans = 
%               A0001,A0003,A0008
%
%------------------------------------------------------------

% Hyatt Moore, IV (August 4, 2014)

if(isempty(cellOfKeys))
    selectStr = '';
else
    [r,c] = size(cellOfKeys);
    if(r>c)
        selectStr = cell2mat(strcat(cellOfKeys,',')');
    else
        selectStr = cell2mat(strcat(cellOfKeys',','));
    end;
    %remove the trailing ','
    selectStr(end) = [];
    
end
