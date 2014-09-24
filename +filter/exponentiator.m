%> @file exponentiator.cpp
%> @brief Exponentiator - point by point exponentiation of input signal.
%> @param data Input signal.
%> @param params Structure of field/value parameter pairs that to adjust filter's
%> behavior.  Field is:
%> - @c pow The power to raise each sample by.
%> @retval filtsig The exponentiated signal.
%> @note written by Hyatt Moore IV, May 31, 2012
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
%> @note modified 9/24/2014 - removed antiquated global reference.
function filtsig = exponentiator(data, params)


% initialize default parameters
defaultParams.pow = 2;
% return default parameters if no input arguments are provided.
if(nargin==0)
    filtsig = defaultParams;
else
    
    if(nargin<2 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future            
            params = defaultParams;
            plist.saveXMLPlist(pfile,params);
        end
    end
    

    filtsig = data.^params.pow;
end
