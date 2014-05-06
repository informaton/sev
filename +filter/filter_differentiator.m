%> @file filter_differentiator.m
%> @brief Differentiator - determines average slope across a sliding
%> window.
%======================================================================
%> @brief 
%> @param data Input signal.
%> @param optional_params Optional structure of field/value parameter pairs that to adjust filter's behavior.
%> @li %c .order Number of samples to use - suggest 5
%> @retval filstig Filtered signal.
%> @note written by Hyatt Moore IV, March 31, 2013
%> @note Modified on 5/6/2014 - removed global CHANNELS_CONTAINER reference
%> @note modified: 3/11/2013 - updated filter weights (b) to more general form
function filtsig = filter_differentiator(data, optional_params)
% 
% written by Hyatt Moore IV, May 31, 2012
%

if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=5; %number of samples to use
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
