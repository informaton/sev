%> @file filter_gauss.m
%> @brief Differentiator - Applies a gaussian kernel filter to the input signal.
%======================================================================
%> @brief data Input signal.
%> @param src_data The first PSG channel
%> @param params Optional structure of field/value parameter pairs that to adjust filter's behavior.
%> @li @c .order Filter order/size - suggest 15
%> @li @c .abs_values Boolean to return absolute vale or not - suggest 0 
%> @li @c .sigma Gaussian parameter - suggest 5
%> @retval filtsig Filtered signal.
%> @note written by Hyatt Moore IV, January, 23, 2013
%> @note Modified on 5/6/2014 - removed global CHANNELS_CONTAINER reference
%> @note modified: 8/21/2014 - changed input checking for optional_params.
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = filter_gauss(src_data, params)
% Gaussian filter

% initialize default parameters
defaultParams.order=15;
defaultParams.abs_value = 0;
defaultParams.sigma = 5;
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

    filtsig = src_data;
    
    
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
end
