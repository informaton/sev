%> @file filter_diff.m
%> @brief Obtains a signal's first order difference or gradient.
%======================================================================
%> @param data Input signal.
%> @param Structure of field/value parameter pairs that to adjust filter's behavior.
%> @li %c .num_diff_runs Nnumber of times to apply the diff operator
%> samples to use - suggest 1.
%> @retval filstig First order difference of difference signal
%> @note written by Hyatt Moore IV, March 10, 2013
%> @note Modified on 5/6/2014 - removed global CHANNELS_CONTAINER reference
function filtsig = filter_diff(data, params)
% MATLAB's diff

if(nargin<2 || isempty(params))

    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.num_diff_runs=1; %number of times to apply the diff operator samples to use
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
