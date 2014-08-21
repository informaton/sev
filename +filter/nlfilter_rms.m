%> @file nlfilter_rms.m
%> @brief Moving root mean square filter
%======================================================================
%> @brief Moving root mean square filter.  
%> @param Vector of sample data to filter.
%> @param Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order Number of samples to calculate RMS over. 
%> @retval Root mean square filtered signal.
%> @note written by Hyatt Moore IV
%> updated on before % February 4, 2013
%> @note modified: 8/21/2014
function filtsig = nlfilter_rms(srcData,params)

%returns the moving rms for a specified window length (win_length)
%mrms is a vector of length length(s).  win_length can be odd or even
% updated by Hyatt Moore , IV
% February 4, 2013


if(nargin<2 || isempty(params))
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


win_length = params.order;

%corner case
if(win_length>=length(srcData)|| win_length<=1)
    filtsig=rms(srcData);
else

       %use the quick version
       qrms.params.win_length_samples=win_length;

       filtsig = filter.nlfilter_quickrms(srcData,qrms.params);
    

       %the grind it out method
       %     ma.params = params;
       %     ma.params.rms = 0;
       %     %square it and mean it
       %     filtsig = sqrt(filter.filter_ma(sig.*sig,ma.params));
    
end;

end
function mrms = rms(sig)
    n=numel(sig);
    mrms = zeros(1,n);
    mrms(1:end) = sqrt(sum(sig.^2)/n);
end