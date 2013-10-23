function filtsig = filter_qma(data, optional_params)
% Moving averager
% written by Hyatt Moore IV, April 20, 2012

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
        params.rms=0;
        plist.saveXMLPlist(pfile,params);
    end
end

filtsig=filter.filter_movavg(data, params.order);

%get root mean square
if(params.rms)
   filtsig = abs(filtsig); 
end