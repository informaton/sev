%> @file filter_differentiator.m
%> @brief Differentiator - determines average slope across a sliding
%> window.
%======================================================================
%> @brief 
%> @param data Input signal.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> @li %c .order Number of samples to use - suggest 5
%> @retval filtsig Filtered signal.
%> @note written by Hyatt Moore IV, March 31, 2013
%> @note Modified on 5/6/2014 - removed global CHANNELS_CONTAINER reference
%> @note modified: 3/11/2013 - updated filter weights (b) to more general form
%> @note modified: 8/21/2014 - changed input checking for optional_params.
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = filter_differentiator(data, params)
% 
% written by Hyatt Moore IV, May 31, 2012
%

% initialize default parameters
defaultParams.order=5;

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
    
    n = params.order;
    denom = 2*n*[n:-1:1,1,1:n];
    %or equivalently
    % denom = 2*abs([-n:-1,0,1:n]);
    
    b = [ones(1,n),0,-ones(1,n)];
    
    b = b./denom;
    
    delay = n;
    filtsig = filter(b,1,data)/n;
    %I do not observe a delay in this filter....
    %account for the delay...
    filtsig = [filtsig((delay+1):end); zeros(delay,1)];
end
