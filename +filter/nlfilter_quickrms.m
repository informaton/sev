%> @file nlfilter_quickrms.m
%> @brief Quick root mean square filter
%======================================================================
%> @brief Quick root mean square filter.  
%> @param Vector of sample data to filter.
%> @param Structure of field/value parameter pairs that to adjust filter's behavior.
%> - win_length Number of samples to calculate RMS over.   (can be even or odd valued)
%> @retval Root mean square filtered signal.
%> @note written by Hyatt Moore IV, on or before August 8, 2013.
%> @note modified: 8/21/2014
function mrms = nlfilter_quickrms(srcData,params)
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
if(win_length>=length(srcData)|| win_length<=1)
    mrms=rms(srcData);
else
    mrms = zeros(1,numel(srcData));
    
    %handle initial values before the window starts moving
    msquares = sum(srcData(1:win_length).^2);
    mrms(1:ceil(window_half)) = sqrt(msquares/win_length);
    
    %move the window through the values
    for k = ceil(window_half)+1:length(srcData)-floor(window_half)
        msquares = msquares - srcData(k-ceil(window_half))^2 + srcData(k+floor(window_half))^2;
        mrms(k) = msquares;
%         mrms(k) = sqrt(msquares/win_length);
    end;
    
    mrms = sqrt(mrms/win_length);
    %finish up the last values
    mrms(length(srcData)-floor(window_half)+1:end)=sqrt(msquares/win_length);
end;


function mrms = rms(s)
n=numel(s);
mrms = zeros(1,n);
mrms(1:end) = sqrt(sum(s.^2)/n);
