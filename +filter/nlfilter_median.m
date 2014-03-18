function output = nlfilter_median(sig,optional_params)
%returns the moving median for a specified window length (win_length) over
%the signal vector sig
%output is a vector with the same length as sig. 
%written by Hyatt Moore IV,
%updated May 10, 2012
% updates March 17, 2014
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
