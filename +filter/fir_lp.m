%> @file fir_hp
%> @brief Finite impulse response lowpass filter.
%======================================================================
%> @brief Finite impulse response lowpass filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 100
%> - freq_hz = 12  (frequency to pass to (from 0))
%> - samplerate = 100
%> @retval The filtered signal. 
% written by Hyatt Moore IV, March 8, 2012
% Modified 8/21/2014
function filtsig = fir_lp(srcData, optional_params)


% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
    samplerate = params.samplerate;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    %     pfile = '+filter/fir_lp.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=100;
        params.samplerate = params.order;
        params.freq_hz = floor(params.samplerate/8);
        plist.saveXMLPlist(pfile,params);
    end
end

delay = (params.order)/2;

b = fir1(params.order,params.freq_hz/params.samplerate*2,'low');

filtsig = filter(b,1,srcData);
%account for the delay...
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
