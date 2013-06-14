function filtsig = nlfilter_rms(src_index,optional_params)
%returns the moving rms for a specified window length (win_length)
%mrms is a vector of length length(s).  win_length can be odd or even
% updated by Hyatt Moore , IV
% February 4, 2013

global CHANNELS_CONTAINER;
if(numel(src_index)>20)
    sig = src_index;
    params = optional_params;
else
    sig = CHANNELS_CONTAINER.getData(src_index);
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
            plist.saveXMLPlist(pfile,params);
        end
    end
end

win_length = params.order;

%corner case
if(win_length>=length(sig)|| win_length<=1)
    filtsig=rms(sig);
else
    ma.params = params;
    ma.params.rms = 0;
    %square it and mean it
    filtsig = sqrt(filter.filter_ma(sig.*sig,ma.params));
 
%     mrms = zeros(1,numel(sig));
%     
%     %handle initial values before the window starts moving
%     msquares = sum(sig(1:win_length).^2);
%     mrms(1:ceil(window_half)) = sqrt(msquares/win_length);
%     
%     %move the window through the values
%     for k = ceil(window_half)+1:length(sig)-floor(window_half)
%         msquares = msquares - sig(k-ceil(window_half))^2 + sig(k+floor(window_half))^2;
%         mrms(k) = msquares;
%     end;
%     
%     mrms = sqrt(mrms/win_length);
%     %finish up the last values
%     mrms(length(sig)-floor(window_half)+1:end)=sqrt(msquares/win_length);
%     
end;

end
function mrms = rms(sig)
    n=numel(sig);
    mrms = zeros(1,n);
    mrms(1:end) = sqrt(sum(sig.^2)/n);
end