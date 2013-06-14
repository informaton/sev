function filtsig = filter_scale(src_index, optional_params)
% scale signal by scalar value
% written by Hyatt Moore IV, February 2, 2013
global CHANNELS_CONTAINER;
if(numel(src_index)<=20)
    filtsig = CHANNELS_CONTAINER.getData(src_index);
else
    filtsig = src_index;
end

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.scalar=1;
        params.make_absolute = 0;
        plist.saveXMLPlist(pfile,params);
    end
end

%get root mean square
if(params.make_absolute)
   filtsig = abs(filtsig); 
end

filtsig = filtsig*params.scalar;