function [PMUSIC freq_vec nfft] = calcPMUSIC(signal_x,Fs,MUSIC_settings,ZeroPad)
% [PMUSIC freq_vec nfft] = calcPMUSIC(signal_x,Fs,MUSIC_settings,ZeroPad)
%MUSIC_settings has the following fields
% MUSIC.modified = handles.user.modified;
% MUSIC.window_length_sec = handles.user.winlen;
% MUSIC.interval_sec = handles.user.fftint;
% MUSIC.num_sinusoids
%

% Hyatt Moore, IV (< June, 2013)
global MUSIC;

if(nargin<4)
    ZeroPad = false;
end;
if(nargin<3)
    MUSIC_settings = MUSIC;
end;

winlen_sec = MUSIC_settings.window_length_sec;
interval_sec = MUSIC_settings.interval_sec;
winlen = winlen_sec*Fs;
interval = interval_sec*Fs;
num_sinusoids = MUSIC_settings.num_sinusoids;
num_signal_window_sec = numel(signal_x)/Fs;

if(~ZeroPad)
    nfft = winlen;
else
    % or use next highest power of 2 greater than or equal to calculate
    % pmusic
    nfft= 2^(nextpow2(winlen));
end;


[s,freq_vec] = pmusic(signal_x(1:winlen),num_sinusoids,nfft,Fs);


cols = numel(freq_vec);
rows = floor((num_signal_window_sec-winlen_sec)/interval_sec)+1;

PMUSIC = zeros(rows,cols); %for winlen = 2 seconds and Fs = 100samples/sec, this breaks the signal into MUSICs of 2sec chunks which are stored per row with bins [0.5 1-50] 

PMUSIC(1,:) = s;

for r = 2:rows
%     disp(num2str(r/rows,'%0.2f'));
   
    start = (r-1)*interval+1;
    stop = start+winlen-1;
    x = signal_x(start:stop);
    PMUSIC(r,:) = pmusic(x,num_sinusoids,nfft);
end;

