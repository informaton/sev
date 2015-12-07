%> @brief Safe wrapper for MATLAB's rmfield method which unfortunately
%> throws an error when the name of the field to remove does not exist in 
%> the parent struct.  This would seem like a fine solution, however it is
%> somewhat annoying when base properties of certain classes or structs
%> (e.g. handle class) change in newer version of MATLAB but you need
%> to continue to support code in previous versions of MATLAB.
%> Written by Hyatt Moore IV
%> December 2, 2015
function structOut = rmfieldSafe(structIn, nameOfFieldToRemove)
    if(nargin<2)
        structOut = [];         % fail silently
    else
        if(~isstruct(structIn) || ~ischar(nameOfFieldToRemove) || ~isfield(structIn,nameOfFieldToRemove))
            structOut = structIn;
        else
            structOut = rmfield(structIn,nameOfFieldToRemove);
        end
    end
end

