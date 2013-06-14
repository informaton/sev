function filtsig = filter_ma(src_index, optional_params)
% Moving averager
% written by Hyatt Moore IV, April 20, 2012

global CHANNELS_CONTAINER;
if(numel(src_index)<=20)
    filtsig = CHANNELS_CONTAINER.getData(src_index);
else
    filtsig = src_index;
end
% sample_rate = CHANNELS_CONTAINER.getSamplerate(src_index);

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=10;
        params.rms = 0;
        plist.saveXMLPlist(pfile,params);
    end
end

%get root mean square
if(params.rms)
   filtsig = abs(filtsig); 
end

delay = floor((params.order)/2);
b = ones(params.order,1);
filtsig = filter(b,1,filtsig)/params.order;

%account for the delay...
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
