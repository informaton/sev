%> @file fir_bs
%> @brief Finite impulse response bandstop filter.
%======================================================================
%> @brief Finite impulse response bandstop filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 100
%> - start_freq_hz = 12
%> - stop_freq_hz= 38
%> - samplerate = 100
%> @retval The filtered signal.
% written by Hyatt Moore IV, March 8, 2012
% updated on 6/15/2012
% Modified 8/21/2014
function filtsig = fir_bs(srcData, params)
%fir bandstop filter
%

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))   
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=100;
        params.samplerate = 100;
        params.start_freq_hz=floor(params.samplerate/8);
        params.stop_freq_hz=floor(params.samplerate/8*3);
        
        plist.saveXMLPlist(pfile,params);
    end
end

delay = (params.order)/2;
w = [params.start_freq_hz,params.stop_freq_hz]/params.samplerate*2;
b = fir1(params.order,w,'stop');

filtsig = filter(b,1,srcData);
%account for the delay...
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
