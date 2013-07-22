function structOut = addfield(structIn, new_field,fillIn)
%structOut = addfield(structIn, new_field)
% adds cell contents of new_field or string new_field as a field(s) to the
% strcture structIn and returns it as structOut.
%
%structOut = addfield(structIn, new_field,fillIn)
% adds cell contents of new_field or string new_field as a field(s) to the
% strcture structIn and returns it as structOut.  If fillIn is true then
% the new fields value is set to the string new_field (fillIn is false by
% default).
%
% opposite to rmfield
%
% Written by Hyatt Moore, IV
% Stanford, CA, 5/16/2013

if(~iscell(new_field))
    new_field = {new_field};
end

if(nargin<3 || isempty(fillIn))
    fillIn = false;
end
structOut = structIn;
for f = 1:numel(new_field)
    if(fillIn)
        structOut.(new_field) = new_field;
    else
        structOut.(new_field) = [];
    end
end