%> @file iir_bp_butter
%> @brief Butterworth bandpass filter.  This function returns the filtered signal using an IIR filter and
% filtering forward and reversed in time (squaring the magnitude spectra
% but no change due to phase shift).
% Designed by Henriette Koch, 2013.
%======================================================================
%> @brief Butterworth bandpass filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 100
%> - start_freq_hz = 12
%> - stop_freq_hz= 38
%> - samplerate = 100
%> @retval The filtered signal.
%> @note original design from Henriette Koch, 2013
%> SEV implementation by Hyatt Mooore, 8/21/2014
%> Method calls filtfilt().
function filtsig = iir_bp_butter(srcData, params)

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    %     pfile = '+filter/fir_bp.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=8;
        params.samplerate = 100;
        params.start_freq_hz=floor(params.order/8);
        params.stop_freq_hz=ceil(params.order/8*3);        
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