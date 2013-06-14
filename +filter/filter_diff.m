function filtsig = filter_diff(src_index, optional_params)
% MATLAB's diff
% written by Hyatt Moore IV, March 10, 2013
global CHANNELS_CONTAINER;
if(numel(src_index)<=20)
    data = CHANNELS_CONTAINER.getData(src_index);
else
    data = src_index;
end
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
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
