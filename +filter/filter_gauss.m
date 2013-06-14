function filtsig = filter_gauss(src_index, optional_params)
% Gaussian filter
% written by Hyatt Moore IV, January, 23, 2013

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
