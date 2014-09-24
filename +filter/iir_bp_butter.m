%> @file iir_bp_butter
%> @brief Butterworth bandpass filter.  This function returns the filtered signal using an IIR filter and
% filtering forward and reversed in time (squaring the magnitude spectra
% but no change due to phase shift).
% Designed by Henriette Koch, 2013.
%======================================================================
%> @brief Butterworth bandpass filter.
%> @param srcData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c order = 100
%> - @c start_freq_hz = 12
%> - @c stop_freq_hz= 38
%> - @c samplerate = 100
%> @retval filtsig The filtered signal.
%> @note original design from Henriette Koch, 2013
%> SEV implementation by Hyatt Mooore, 8/21/2014
%> Method calls filtfilt().
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = iir_bp_butter(srcData, params)

% initialize default parameters
defaultParams.order=8;
defaultParams.samplerate = 100;
defaultParams.start_freq_hz=floor(defaultParams.order/8);
defaultParams.stop_freq_hz=ceil(defaultParams.order/8*3);

% return default parameters if no input arguments are provided.
if(nargin==0)
    filtsig = defaultParams;
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

    
    
    N   = params.order;    % Order
    Fc1 = params.start_freq_hz;  % First Cutoff Frequency
    Fc2 = params.stop_freq_hz;   % Second Cutoff Frequency
    Fs = params.samplerate;
    % Construct a FDESIGN object and call BUTTER method.
    h  = fdesign.bandpass('N,F3dB1,F3dB2', N, Fc1, Fc2, Fs);
    Hd = design(h, 'butter');
    
    % Filter coefficients
    [b,a] = sos2tf(Hd.sosMatrix,Hd.Scalevalues);
    
    filtsig = filtfilt(b,a,srcData);
end