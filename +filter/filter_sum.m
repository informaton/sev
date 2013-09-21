function filtsig = filter_sum(src_index, optional_params)
% Moving summer
% written by Hyatt Moore IV, April 20, 2012
global CHANNELS_CONTAINER;
if(numel(src_index)<=20)
    filtsig = CHANNELS_CONTAINER.getData(src_index);
else
    filtsig = src_index(:); %make a row vector
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
        params.order=10;
        params.rms = 0;
        plist.saveXMLPlist(pfile,params);
    end
end

%get instantaneous root mean square
if(params.rms)
   filtsig = abs(filtsig); 
end

delay = floor((params.order)/2);
b = ones(params.order,1);
filtsig = filter(b,1,filtsig);
%account for the delay...for detection algorithms
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
