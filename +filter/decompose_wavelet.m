function filtsig = decompose_wavelet(src_index, optional_params)
% written by Hyatt Moore IV, November, 20_ish 2012
global CHANNELS_CONTAINER;
if(numel(src_index)<=20)
    data = CHANNELS_CONTAINER.getData(src_index);
else
    data = src_index;
end

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    matfile = fullfile(fileparts(mfilename('fullpath')),'decompose_wavelet.mat');
    
    if(exist(matfile,'file'))
        %load it
        mStruct= load(matfile);
        params = mStruct.params;
    else
        max_decompositions = 10;
        params.wname = 'db1';
        params.threshhold = 50;
        params.num_levels = 5;
        params.soft_threshhold = 1;        
        params.decomposition_levels = true(max_decompositions); 
        params.approximation_level = true;
        save(matfile,'params');
    end
end

len = numel(data);
pow = 2^params.num_levels;

%zeropad if necessary
if rem(len,pow)>0
    sOK = ceil(len/pow)*pow;
    data = [data(:);zeros(sOK-len,1)];
end

wav_sig = swt(data,params.num_levels,params.wname);

%go through the detail coefficients %1 = details, 5 = details 5, 6 = approx
%5?
for d=1:size(wav_sig,1)-1
    if(params.decomposition_levels(d))
        rejects = abs(wav_sig(d,:))<params.threshhold;
        
        wav_sig(d,rejects) = 0;
        
        if(params.soft_threshhold)
            wav_sig(d,~rejects) = sign(wav_sig(d,~rejects)).*(abs(wav_sig(d,~rejects))-params.threshhold);
        end
    else
        wav_sig(d,:) = 0;
    end    
end

if(~params.approximation_level)
    wav_sig(end,:) = 0;
end

filtsig = iswt(wav_sig,params.wname);

%adjust zero-padding as necessary
if rem(len,pow)>0
    filtsig  = filtsig(1:len);
end

