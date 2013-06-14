function filtsig = filter_differentiator(src_index, optional_params)
% Differentiator - determines average slope across a sliding window
% written by Hyatt Moore IV, May 31, 2012
%
%modified: 3/11/2013 - updated filter weights (b) to more general form
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
        params.order=5; %number of samples to use
        plist.saveXMLPlist(pfile,params);
    end
end
n = params.order;
denom = 2*n*[n:-1:1,1,1:n];
%or equivalently 
% denom = 2*abs([-n:-1,0,1:n]);

b = [ones(1,n),0,-ones(1,n)];

b = b./denom;

delay = n;
filtsig = filter(b,1,data)/n;
%I do not observe a delay in this filter....
%account for the delay...
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
