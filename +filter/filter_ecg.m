function ECG_sig = filter_ecg(sigData,params)
%> @brief Filters ECG signal according to Arzeno et al. 2008, using a
%> kaiser window filter with passband 10-25 Hz and 4 Hz transition bands. 
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> @retval filtSig The filtered signal. 

%> ECG_sig = ECG_filter(ECG,Fs), where ECG is the ECG signal, and Fs is the
%> sampling frequency. ECG_sig is the filtered signal.

%> @note Written by: Emil G.S. Munk, as part of the master thesis project:
%> "Automatic Classification of Obstructive Sleep Apnea".

%> @note Imported to SEV on 12/24/2015 by Hyatt Moore IV

% return default parameters if no input arguments are provided.
if(nargin==0)
    ECG_sig = [];
else
    if(nargin<2 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future
            params = defaultParams;
            plist.saveXMLPlist(pfile,params);
        end
    end

    [n,Wn,bta,filtype] = kaiserord(...
        [6 10 25 29],[0 1 0],[0.001 0.057501127785 0.001],params.samplerate);
    b = fir1(n, Wn, filtype, kaiser(n+1,bta), 'noscale');
    ECG_sig = filtfilt(b,1,sigData);
    
    
end
