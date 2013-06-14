function filtsig = nlfilter_max_future(src_index, optional_params)
% nonlinear filter that returns the maximum value obtained in the neighborhood 
% defined in the future range [n, n+params.win_size-1] where n is the current
% sample point in the signal
% written by Hyatt Moore IV, April 21, 2012
global CHANNELS_CONTAINER;

if(numel(src_index)<=20)
    sig = CHANNELS_CONTAINER.getData(src_index);
else
    sig = src_index;
end

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = '+filter/nlfilter_max_future.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.win_size = 20; %look 10 beats into the future...
        plist.saveXMLPlist(pfile,params);
    end
end
win_size = params.win_size;
filtsig = sig;
futureInd = win_size;
maxInd = 0;
for k=1:numel(filtsig)-win_size
    if(maxInd<k)
        [maxVal,maxInd] = max(sig(k:futureInd));
        maxInd = (futureInd-1)+maxInd;
    else
        if(sig(futureInd)>=maxVal)
            maxInd = futureInd;
            maxVal = sig(futureInd);
        end
    end
    filtsig(k)=maxVal;
    futureInd=futureInd+1;
end
filtsig(k:end)=max(sig(k:end));  %or could just set = to maxVal...
