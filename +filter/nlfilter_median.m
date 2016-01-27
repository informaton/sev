%> @file nlfilter_median
%> @brief Non linear moving median filter.
%> Returns the moving median for a specified window length over
%> the signal vector sig.  Returned signal is a vector with the same length as sig. 
%======================================================================
%> @brief Non linear moving median filter.
%> Returns the moving median for a specified window length (order) over
%> the signal vector sig.  Returned signal is a vector with the same length as sig. 
%> @param sig Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c order = 100  (filter order; window length to calculate median from)
%> @retval filtsig The nonlinear filtered signal. 
%> @note Uses MATLAB medfilt1() method
%> written by Hyatt Moore IV,
%> updated May 10, 2012
%> updates March 17, 2014
%> updated August 21, 2014 - commenting
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = nlfilter_median(sig,params)
%returns the moving median for a specified window length (win_length) over
%the signal vector sig
%output is a vector with the same length as sig. 


% initialize default parameters
defaultParams.order = 100;

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
    
    
    win_length = params.order;
    
    
    % window_half = win_length/2;
    if(win_length>=length(sig)|| win_length<=1)
        filtsig = zeros(size(sig));
        filtsig(1:end) = median(sig);
    else
        tic
        filtsig = medfilt1(sig,win_length);
        toc
        
        %     output = zeros(1,numel(sig));
        %
        %     %handle initial values before the window starts moving
        %     output(1:ceil(window_half)) = median(sig(1:win_length));
        %
        %     %move the window through the values
        %     search_range = 1:win_length;
        %     for k = ceil(window_half)+1:length(sig)-floor(window_half)
        %         search_range = search_range+1;
        %         output(k) = median(sig(search_range));
        %     end;
        %
        %     %finish up the last values
        %     output(length(sig)-floor(window_half)+1:end)=median(sig(end-win_length+1:end));
    end;
end
