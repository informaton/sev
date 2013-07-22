function [struct1_out, struct2_out] = combineStructs(struct_1,struct_2, metricToCombine, fieldToAlignOn)
%   combines the field 'fieldToCombine', which exists in struct1 and
%   other_Struct using the intersection of the values from both struct's
%   fields 'fieldToCombineOn'.  The output is structs with field 'fieldToCombine', which
%   have the same intersecting values of fieldToCombine.
%

%   written 1/15/2013
%   by Hyatt Moore, IV
%   Stanford University, Stanford CA

% [~, i] = setdiff(struct1.(fieldToAlignOn),other_Struct.(fieldToAlignOn));
% struct1_out.(metricToCombine)(i) = [];  %remove the ones that are missing from tmpdetectorMat
% struct1_out.(fieldToAlignOn)(i) = [];  %remove the ones that are missing from tmpdetectorMat
[~, det_i, tmp_i] = intersect(struct_1.(fieldToAlignOn),struct_2.(fieldToAlignOn));

if(ischar(metricToCombine)&&strcmpi(metricToCombine,'all'))
    metricToCombine = fieldnames(struct_1);
end

if(~iscell(metricToCombine))
    metricToCombine = {metricToCombine};
end

for m=1:numel(metricToCombine)
    struct1_out.(metricToCombine{m}) = struct_1.(metricToCombine{m})(det_i);
    struct2_out.(metricToCombine{m}) = struct_2.(metricToCombine{m})(tmp_i);
end

struct1_out.(fieldToAlignOn) = struct_1.(fieldToAlignOn)(det_i);
struct2_out.(fieldToAlignOn) = struct_2.(fieldToAlignOn)(tmp_i);

end