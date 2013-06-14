function output = nlfilter_median(src_index,optional_params)
%returns the moving median for a specified window length (win_length) over
%the signal vector s
%output is a vector with the same length as s. 
%written by Hyatt Moore IV,
%updated May 10, 2012
global CHANNELS_CONTAINER;
if(numel(src_index)>20)
    sig = src_index;
else
    sig = CHANNELS_CONTAINER.getData(src_index);
end
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
        params.abs = 1;
        params.order=100;
        plist.saveXMLPlist(pfile,params);
    end
end

win_length = params.order;


% window_half = win_length/2;
if(win_length>=length(sig)|| win_length<=1)    
    output = zeros(size(sig));
    output(1:end) = median(sig);
else
    tic
    output = medfilt1(sig,params.order);
    toc
%     output = zeros(1,numel(sig));
%     
%     %handle initial values before the window starts moving    
%     output(1:ceil(window_half)) = median(sig(1:win_length));
%     
%     %move the window through the values
%     search_range = 1:win_length;
%     for k = ceil(window_half)+1:length(sig)-floor(window_half)
%         search_range = search_range+1;
%         output(k) = median(sig(search_range));
%     end;
%     
%     %finish up the last values
%     output(length(sig)-floor(window_half)+1:end)=median(sig(end-win_length+1:end));
end;
