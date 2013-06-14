function filtsig = exponentiator(src_index, optional_params)
% Exponentiator - point by point exponentiation of input dat
% written by Hyatt Moore IV, May 31, 2012
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
        params.pow=2; %number of samples to use
        plist.saveXMLPlist(pfile,params);
    end
end

filtsig = data.^params.pow;
