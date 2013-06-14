function filtsig = fir_hp(src_index, optional_params)
% written by Hyatt Moore IV, March 8, 2012
% updated 6/15/2012 to incorporate direct data input in addition to a
% channel reference
global CHANNELS_CONTAINER;

if(numel(src_index)>20)
    filtsig = src_index;
    params = optional_params;
    samplerate = params.samplerate;
else
    filtsig = CHANNELS_CONTAINER.getData(src_index);
    samplerate = CHANNELS_CONTAINER.getSamplerate(src_index);
    
    % this allows direct input of parameters from outside function calls, which
    %can be particularly useful in the batch job mode
    if(nargin==2 && ~isempty(optional_params))
        params = optional_params;
    else
        pfile = strcat(mfilename('fullpath'),'.plist');
        %     pfile = '+filter/fir_hp.plist';
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future
            params.order=100;
            params.freq_hz = floor(samplerate/8);
            plist.saveXMLPlist(pfile,params);
        end
    end
end

delay = (params.order)/2;

b = fir1(params.order,params.freq_hz/samplerate*2,'high');

filtsig = filter(b,1,filtsig);
%account for the delay...
filtsig = [filtsig((delay+1):end); zeros(delay,1)];
