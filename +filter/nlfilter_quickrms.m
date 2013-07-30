function mrms = nlfilter_quickrms(s,params)
% quick rms
%returns the moving rms for a specified window length (win_length)
%mrms is a vector of length length(s).  win_length can be odd or even
%
if(nargin<2 || isempty(params))
    pfile = strcat(mfilename('fullpath'),'.plist');
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.win_length_samples=500;
        plist.saveXMLPlist(pfile,params);
    end
end


win_length = params.win_length_samples;


window_half = win_length/2;
if(win_length>=length(s)|| win_length<=1)
    mrms=rms(s);
else
    mrms = zeros(1,numel(s));
    
    %handle initial values before the window starts moving
    msquares = sum(s(1:win_length).^2);
    mrms(1:ceil(window_half)) = sqrt(msquares/win_length);
    
    %move the window through the values
    for k = ceil(window_half)+1:length(s)-floor(window_half)
        msquares = msquares - s(k-ceil(window_half))^2 + s(k+floor(window_half))^2;
        mrms(k) = msquares;
%         mrms(k) = sqrt(msquares/win_length);
    end;
    
    mrms = sqrt(mrms/win_length);
    %finish up the last values
    mrms(length(s)-floor(window_half)+1:end)=sqrt(msquares/win_length);
end;


function mrms = rms(s)
n=numel(s);
mrms = zeros(1,n);
mrms(1:end) = sqrt(sum(s.^2)/n);
