%> @file filter_diff.m
%> @brief Obtains a signal's first order difference or gradient.
%======================================================================
%> @param data Input signal.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> @li %c .num_diff_runs Nnumber of times to apply the diff operator
%> samples to use - suggest 1.
%> @retval filtsig First order difference of difference signal
%> @note written by Hyatt Moore IV, March 10, 2013
%> @note Modified on 5/6/2014 - removed global CHANNELS_CONTAINER reference
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = filter_diff(data, params)
% MATLAB's diff

% initialize default parameters
defaultParams.num_diff_runs = 1;
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
    
    dx = 1;
    if(params.num_diff_runs>0)
        %     dx = 1/params.samplerate;
        for d=1:params.num_diff_runs
            data = [0; diff(data)].^2;
        end
    end
    filtsig = data/dx;
end
