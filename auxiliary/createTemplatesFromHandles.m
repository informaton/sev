function templates =createTemplatesFromHandles(handles)
%creates templates from the passed handles that can be used to create
%similar handles with matching properties passing the templates as the
%property for newly created handles of same type.
%
%the added Position and removal is to bypass a warning that pops because
%MATLAB does not like the units field to follow the position field when
%initializing a uicontrol- notice that the copy is a lower case and thus
%different than the upper-cased Position name
%

%Hyatt Moore, IV
% < June, 2013

templates = cell(size(handles));
for h=1:numel(handles)
    tmp_copy = get(handles(h));
    
    tmp_copy = rmfield(tmp_copy,'Type');
    tmp_copy = rmfield(tmp_copy,'Extent');
    tmp_copy = rmfield(tmp_copy,'BeingDeleted');
    tmp_copy.position = tmp_copy.Position;
    tmp_copy = rmfield(tmp_copy,'Position');

    templates{h} = tmp_copy;
end