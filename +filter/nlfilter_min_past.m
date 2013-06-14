function filtsig = nlfilter_min_past(src_index, optional_params)
% nonlinear filter that returns the minimum value obtained in the past neighborhood 
% defined in the range [n-params.win_size+1, n] where n is the current
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
    pfile = '+filter/nlfilter_min_past.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.win_size = 10;
        plist.saveXMLPlist(pfile,params);
    end
end
win_size = params.win_size;
filtsig = sig;
[minVal,minInd] = min(sig(1:win_size));
filtsig(1:win_size)=minVal;
lastInd = 1;

for k=win_size+1:numel(filtsig)
    lastInd = lastInd+1;
    if(minInd<lastInd)
        [minVal,minInd] = min(sig(lastInd:k));
        minInd = (lastInd-1)+minInd;
    else
        if(sig(k)<=minVal)
            minInd = k;
            minVal = sig(k);
        end
    end
    filtsig(k)=minVal;
end

lastInd = 1;

%this is 1.6 seconds slower than the above method (8.8 vs 10.4)
for k=win_size+1:numel(filtsig)
    lastInd = lastInd+1;
    filtsig(k) = min(sig(lastInd:k));
end