function mstd = nlfilter_std(src_index,optional_params)
%returns the moving std for a specified window length (win_length)
%mstd is a vector of length length(s).  win_length can be odd or even
global CHANNELS_CONTAINER;
if(numel(src_index)>5)
    data = src_index;
    params.win_length_sec = optional_params.win_length_sec;
    samplerate = optional_params.samplerate;
else
    data = CHANNELS_CONTAINER.getData(src_index);
    samplerate = CHANNELS_CONTAINER.getSamplerate(src_index);
    
    % this allows direct input of parameters from outside function calls, which
    %can be particularly useful in the batch job mode
    if(nargin==2 && ~isempty(optional_params))
        params = optional_params;
    else
        pfile = strcat(mfilename('fullpath'),'.plist');
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future
            params.win_length_sec = 0.15;
            plist.saveXMLPlist(pfile,params);
            
        end
    end
    
end

% moving standard deviation = 
% moving variance filter = 
% 
% var(x) = mean(x^2)-mean(x)^2;
% std(x) = sqrt(var(x));
moving_win_len = ceil(params.win_length_sec*samplerate);
params.order = moving_win_len;
params.rms = 0;
mstd = sqrt(filter.filter_ma(data.^2,params)-filter.filter_ma(data,params).^2);