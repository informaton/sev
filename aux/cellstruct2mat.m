function mat_out = cellstruct2mat(cell_of_struct, fieldToGrab)
%   Returns the field, fieldToGrab, from each structure in the cell array
%   cell_of_struct and returns it as a vector of size cell_of_struct

%   written May, 15, 2013
%   by Hyatt Moore, IV
%   Stanford University, Stanford CA

if(~iscell(cell_of_struct))
    mat_out = NaN;
else
    if(~isstruct(cell_of_struct{1}) || ~isfield(cell_of_struct{1},fieldToGrab))
        mat_out = NaN;
    else
        mat_out = zeros(size(cell_of_struct));
        for c=1:numel(cell_of_struct)
            mat_out(c) = cell_of_struct{c}.(fieldToGrab);
        end
    end
end

