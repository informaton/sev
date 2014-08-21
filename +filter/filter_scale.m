%> @file filter_scale
%> @brief Single element finite impulse response bandpass filter (i.e. multiplication by a scalar value).
%======================================================================
%> @brief Scale signal by a scalar value.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - scalar = 1
%> - make_absolute = 0
% written by Hyatt Moore IV, February 2, 2013
% Modified 8/21/2014
function filtsig = filter_scale(sigData, params)
% scale signal by scalar value

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.scalar=1;
        params.make_absolute = 0;
        plist.saveXMLPlist(pfile,params);
    end
end

filtsig = sigData*params.scalar;
%get root mean square
if(params.make_absolute)
   filtsig = abs(filtsig); 
end
