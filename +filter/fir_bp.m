function filtsig = fir_bp(src_index, optional_params)
%fir bandpass filter
%
% written by Hyatt Moore IV, March 8, 2012
global CHANNELS_CONTAINER;

if(numel(src_index)>20)
    filtsig = src_index;
else

    filtsig = CHANNELS_CONTAINER.getData(src_index);
    samplerate = CHANNELS_CONTAINER.getSamplerate(src_index);
end
% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
    samplerate = params.samplerate;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    %     pfile = '+filter/fir_bp.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=100;
        params.start_freq_hz=floor(samplerate/8);
        params.stop_freq_hz=floor(samplerate/8*3);
        plist.saveXMLPlist(pfile,params);
    end
end

w = [params.start_freq_hz,params.stop_freq_hz]/samplerate*2;
b = fir1(params.order,w,'bandpass');

filtsig = filter(b,1,filtsig);
%account for the delay...
delay = (params.order)/2;
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
