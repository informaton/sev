function filtsig = nlfilter_median_baseline_remover(data, optional_params)
% Median baseline removal filter
% written by Hyatt Moore IV, March 17, 2014

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
        params.abs = 0;
        params.order=100;
        plist.saveXMLPlist(pfile,params);
    end
end

filtsig=filter.nlfilter_median(data, params);
filtsig = data-filtsig;

if(params.abs)
   filtsig = abs(filtsig); 
end