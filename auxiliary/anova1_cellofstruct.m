function p = anova1_cellofstruct(cellofstruct,field1, field2)
%function p = anova1_cellofstruct(cellofstruct,field1, field2)
% calculate anova (i.e. anova1) between different cell elements of the cell
% of structs (cellofstruct) for the sub field .(field1) or
% .(field1).(field2)
% 
% This kind of problem pops up with the mym MySQL database interactions.
% Hyatt Moore, IV
% < June, 2013

%need to convert the cell of structs to a cell of doubles which can then be
%flattened and passed to anova1
if(~iscell(cellofstruct) || nargin<2 || isempty(field1))
    p = nan;
    fprintf(1,'Failed on myANOVA\n');
else
    
    cell_of_doubles = cell(size(cellofstruct));
    if(nargin>=3 && ~isempty(field2))
        for c=1:numel(cellofstruct)
            cell_of_doubles{c} = cellofstruct{c}.(field1).(field2)(:);
        end
    else
        for c=1:numel(cellofstruct)
            cell_of_doubles{c} = cellofstruct{c}.(field1)(:);
        end
    end
    
    [values,categories] = flattenCell(cell_of_doubles);
    [p,~,~] = anova1(values,categories,'off');
   
end

