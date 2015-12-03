%> @file nlfilter_ani
%> @brief Calculates the Analgesia-Nociception-Index (ANI) as described by 
%> PhysioDoloris: a monitoring device for Analgesia / Nociception balance
%> evaluation using Heart Rate Variability analysis.
%======================================================================
%> @brief 
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> @retval filtsig The filtered signal. 
%> written by Hyatt Moore IV, December 3, 2015

%> @note Requires heart rate detection classification method,
%> interpoliation or spline, and wavelet decomposition filtering methods:
%> -
%> - 
%> - 
function filtsig = nlfilter_ani(sigData, params)

% initialize default parameters
defaultParams.order=10;
defaultParams.abs = 0;
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
    
    % Currently this just calculates the moving average and needs to be
    % updated.
    % get root mean square
    if(params.abs)
        sigData = abs(sigData);
    end
    
    delay = floor((params.order)/2);
    b = ones(params.order,1);
    filtsig = filter(b,1,sigData)/params.order;
    
    %account for the delay...
    filtsig = [filtsig((delay+1):end); zeros(delay,1)];
end
