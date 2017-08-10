function [psd, freq_vec, nfft, U_psd, U_power] = calcPSD(signal_x,Fs,PSD_settings,ZeroPad)
%PSD_settings has the following fields
% PSD.wintype = handles.user.wintype;
% PSD.modified = handles.user.modified;
% PSD.FFT_window_sec = handles.user.winlen;
% PSD.interval_sec = handles.user.fftint;
% PSD.removemean = true;
% PSD.spectrum_type = {'psd','power','none'}
%
%calculate the power spectral density of signal_x with sampling rate of FS,
%over a winlen second segments done every interval seconds
%calculations are done using the fft with the specified window type (wintype)
%and zero padding
%as necessary...
%freq_vec is a vector containing the center points around which the histogram
%was made across
%nfft is the fft size that was used in calculating the PSD...
%wintype is a string containing the window to be used...
%NextPowOfTwo is a boolean that determines if FFT zeropads to the next
%power of two
%
%Calculates the psd using periodogram method more or less . . .

%> Written by Hyatt Moore, IV (sometime before 14october2010)
%> modified 14october2010 to remove the waitbar screen
%> modified 5Aug2011 to update PSD global variable usage and change to
%> passing a PSD_settings struct instead of individual variable names
%> Modified November 27, 2012 - zeropad signal_x when it is smaller than
%> PSD_settings.win_len*Fs

%> Modified 8/5/2016 to allow for calculation of power as well as psd
%> (normalized by sampling frequency)

    % Ensure we are dealing with row vectors here;
    signal_x = signal_x(:);
    
    if(nargin<4)
        ZeroPad = false;
        
        if(nargin<2)
            Fs = 100;
        end
        
        if(nargin<3)
            len_sec = floor(numel(signal_x)/Fs);
            defaultSettings.FFT_window_sec = len_sec;
            signal_x = signal_x(1:len_sec*Fs);
            defaultSettings.interval_sec = len_sec;
            defaultSettings.wintype = 'rectwin';
            defaultSettings.removemean = true;
            defaultSettings.spectrum_type = 'psd';
            PSD_settings = defaultSettings;
        end        
        
    end;
    
    winlen = PSD_settings.FFT_window_sec;
    interval = PSD_settings.interval_sec;
    wintype = PSD_settings.wintype;
    RemoveMean = PSD_settings.removemean;
    
    if(~isfield(PSD_settings,'spectrum_type'))
        PSD_settings.spectrum_type = 'psd';
    end
    
    spectrum_type = PSD_settings.spectrum_type;
    
    % h = waitbar(0,'Calculating Power Spectal Density');
    
    % rows = floor(length(signal_x)/Fs/winlen) %- the old way of doing things back
    % to back...
    
    num_signal_window_sec = length(signal_x)/Fs;
    
    rows = floor((num_signal_window_sec-winlen)/interval)+1;
    
    
    if(~ZeroPad)
        nfft = winlen*Fs;
    else
        % or use next highest power of 2 greater than or equal to length(x) to
        % calculate FFT.
        nfft= 2^(nextpow2(winlen*Fs));
    end;
    
    if(rows==0)
        signal_x = [signal_x(:);zeros(nfft-numel(signal_x),1)];
        rows = 1;
    end
    % win = window(eval(['@' wintype]),nfft);
    win = eval([wintype '(' num2str(nfft) ')']);
    
    
    % PSD window normalization
    U_psd = win'*win;  %Window normalization
    
    
    % Mean square or power normalization
    U_power = sum(win)^2;
    
    U_none = 1;  % No normalization.
    
    if(strcmpi(spectrum_type,'power'))
        U = U_power;
    elseif(strcmpi(spectrum_type,'psd'))
        U = U_psd;
    elseif(strcmpi(spectrum_type,'none'))
        U = U_none;
    else
        U = U_psd;
    end
    
    % Calculate the numberof unique points
    NumUniquePts = ceil((nfft+1)/2);
    
    cols = NumUniquePts;
    psd = zeros(rows,cols); %for winlen = 2 seconds and Fs = 100samples/sec, this breaks the signal into PSDs of 2sec chunks which are stored per row with bins [0.5 1-50]
    
    % This is an evenly spaced frequency vector with NumUniquePts points.
    freq_vec = (0:NumUniquePts-1)*Fs/nfft;
    
    isODD = rem(nfft,2);
    
    
    for r = 1:rows
        % Take fft, padding with zeros so that length(fftx) is equal to nfft
        %     x = signal_x((r-1)*winlen*Fs+1:r*winlen*Fs);
        start = (r-1)*interval*Fs+1;
        x = signal_x(start:start+winlen*Fs-1);
        
        if(RemoveMean)
            mx = mean(x);
            x = x-mx;
        end;
        x = x.*win;
        
        %     fft_x= abs(fft(x,nfft));
        %     Sxx = fft_x.^2/U;
        
        
        %my original way of doing this, but had not taken into account odd or
        %eveness of nfft...
        %     Sxx = (fft_x(1:NumUniquePts).^2)'/U;    % Pxx = [Sxx(1); Sxx(2:end)*2]./fs;
        %     psd(r,:) = [Sxx(1), Sxx(2:end)*2]./Fs; %multiple by 2 due to it being a single sided spectrum
        
        
        
        %see MATLAB's computePSD function
        fft_x= fft(x,nfft);
        
        Sxx = fft_x.*conj(fft_x)/U;
        
        if isODD
            select = 1:(nfft+1)/2;  % ODD
            Sxx_unscaled = Sxx(select,:); % Take only [0,pi] or [0,pi)
            Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end,:)];  % Only DC is a unique point and doesn't get doubled
        else
            select = 1:nfft/2+1;    % EVEN
            Sxx_unscaled = Sxx(select,:); % Take only [0,pi] or [0,pi)
            Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end-1,:); Sxx_unscaled(end,:)]; % Nyquist point also unique
        end
        
        %         psd(r,:) = Sxx;
        
        
        % Otherwise we are biasing more towards those who have additional
        % power.  It appears that they are larger.
        psd(r,:) = Sxx./nfft;
        
        if(RemoveMean)
            %         psd(r,1) = mx;
        end;
        
    end;
    
    if(strcmpi(spectrum_type,'psd'))
        psd = psd/Fs;
    end



