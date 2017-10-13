function ECG_sig = ECG_filter(ECG,Fs)
% ECG_FILTER - Filters ECG signal according to Arzeno et al. 2008, using a
% kaiser window filter with passband 10-25 Hz and 4 Hz transition bands. 
%
% ECG_sig = ECG_filter(ECG,Fs), where ECG is the ECG signal, and Fs is the
% sampling frequency. ECG_sig is the filtered signal.

% Written by: Emil G.S. Munk, as part of the master thesis project:
% "Automatic Classification of Obstructive Sleep Apnea".

[n,Wn,bta,filtype] = kaiserord(...
    [6 10 25 29],[0 1 0],[0.001 0.057501127785 0.001],Fs);
b = fir1(n, Wn, filtype, kaiser(n+1,bta), 'noscale');
ECG_sig = filtfilt(b,1,ECG);