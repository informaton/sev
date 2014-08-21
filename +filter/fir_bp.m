%> @file fir_bp
%> @brief Finite impulse response bandpass filter.
%======================================================================
%> @brief Finite impulse response bandpass filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 100
%> - start_freq_hz = 12
%> - stop_freq_hz= 38
%> - samplerate = 100
%> @retval The filtered signal.
% written by Hyatt Moore IV, March 8, 2012
% Modified 8/21/2014
function filtsig = fir_bp(sig_data, params)
%fir bandpass filter


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
        params.order=100;
        params.samplerate = 100;
        params.start_freq_hz=floor(params.order/8);
        params.stop_freq_hz=ceil(params.order/8*3);        
        plist.saveXMLPlist(pfile,params);
    end
end

w = [params.start_freq_hz,params.stop_freq_hz]/params.samplerate*2;
b = fir1(params.order,w,'bandpass');

filtsig = filter(b,1,sig_data);
%account for the delay...
delay = (params.order)/2;
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
