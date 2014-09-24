%> @file fir_hp
%> @brief Finite impulse response lowpass filter.
%======================================================================
%> @brief Finite impulse response lowpass filter.
%> @param srcData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 100
%> - freq_hz = 12  (frequency to pass to (from 0))
%> - samplerate = 100
%> @retval filtsig The filtered signal. 
%> written by Hyatt Moore IV, March 8, 2012
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = fir_lp(srcData, params)

% initialize default parameters
defaultParams.order=8;
defaultParams.samplerate = 100;
defaultParams.freq_hz=floor(defaultParams.samplerate/3);

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

    delay = (params.order)/2;
    
    b = fir1(params.order,params.freq_hz/params.samplerate*2,'low');
    
    filtsig = filter(b,1,srcData);
    %account for the delay...
    filtsig = [filtsig((delay+1):end); zeros(delay,1)];
end
