function filtsig = denoise_wavelet(src_index, optional_params)
%fir bandpass filter
%
% written by Hyatt Moore IV, March 8, 2012
global CHANNELS_CONTAINER;
if(numel(src_index)<=20)
    data = CHANNELS_CONTAINER.getData(src_index);
%     sample_rate = CHANNELS_CONTAINER.getSamplerate(src_index);
else
    data = src_index;
%     sample_rate = 100;
end

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
        params.threshold = 50;
        params.soft_threshold = 1;
        params.num_levels=5;
        plist.saveXMLPlist(pfile,params);
    end
end

wname = 'db1';
wname = 'haar';
% [f1,f2]=wfilters(wname,'l')

%see wfilters
% [LO_D,HI_D,LO_R,HI_R] = WFILTERS('wname')
% [Coef_o,Levels] = wavedec(data,params.num_levels,wname);
len = numel(data);
pow = 2^params.num_levels;

%zeropad if necessary
if rem(len,pow)>0
    sOK = ceil(len/pow)*pow;
    data = [data(:);zeros(sOK-len,1)];
end


wav_sig = swt(data,params.num_levels,wname);
%go through the detail coefficients %1 = details, 5 = details 5, 6 = approx
%5?
for k=1:size(wav_sig,1)-1
    rejects = wav_sig(k,:)<params.threshold;
    
    wav_sig(k,rejects) = 0;

    if(params.soft_threshold)
        wav_sig(k,~rejects) = sign(wav_sig(k,~rejects)).*(abs(wav_sig(k,~rejects))-params.threshold);
    end
end
filtsig = iswt(wav_sig,wname);

%adjust zero-padding as necessary
if rem(len,pow)>0
    filtsig  = filtsig(1:len);
end
