%> @file filter_gauss.m
%> @brief Differentiator - Applies a gaussian kernel filter to the input signal.
%======================================================================
%> @brief data Input signal.
%> @param src_data The first PSG channel
%> @param Optional structure of field/value parameter pairs that to adjust filter's behavior.
%> @li @c .order Filter order/size - suggest 15
%> @li @c .abs_values Boolean to return absolute vale or not - suggest 0 
%> @li @c .sigma Gaussian parameter - suggest 5
%> @retval filstig Filtered signal.
%> @note written by Hyatt Moore IV, January, 23, 2013
%> @note Modified on 5/6/2014 - removed global CHANNELS_CONTAINER reference
%> @note modified: 8/21/2014 - changed input checking for optional_params.
function filtsig = filter_gauss(src_data, params)
% Gaussian filter

filtsig = src_data;

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=15;
        params.abs_values = 0;
        params.sigma = 5;
        plist.saveXMLPlist(pfile,params);
    end
end

%get root mean square
if(params.abs_values)
   filtsig = abs(filtsig); 
end
x = linspace(-params.order / 2, params.order / 2, params.order);
gaussFilter = exp(-x.^2/(2*params.sigma^2));
gaussFilter = gaussFilter/sum(gaussFilter); % normalize

delay = floor((params.order)/2);
filtsig = filter(gaussFilter,1,filtsig);

%account for the delay...
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
