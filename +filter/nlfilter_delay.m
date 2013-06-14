function filtsig = nlfilter_delay(src_index, optional_params)
% delay or advance
% written by Hyatt Moore IV
%September 13, 2012
% params.samples2delay=k;  y(n)=x(n-k) %input negative values to advance
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
        params.samples2delay=100;  %input negative values to advance...
        plist.saveXMLPlist(pfile,params);
    end
end

samples2delay = round(params.samples2delay);  %ensure we are dealing with integer values here

if(samples2delay>0)
    filtsig = [zeros(samples2delay,1);filtsig(1:end-samples2delay)];
elseif(samples2delay<0)
    samples2delay = abs(samples2delay);
    filtsig = [filtsig(samples2delay+1:end); zeros(samples2delay,1)];
else
    %do nothing - no shifting occurred
end
