%> @file denoise_wavelet.cpp
%> @brief Applies wavelet denoising to the input signal using @c haar kernel.  
%> @param data Input signal.
%> @param params Structure of field/value parameter pairs that to adjust filter's
%> behavior.  Fields include:
%> - @c threshold 
%> - @c soft_threshold
%> - @c num_levels 
%> @retval filtsig The wavelet denoised signal.
%> @note written by Hyatt Moore IV, March 8, 2012
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
%> @note modified 9/24/2014 - removed antiquated global reference.
function filtsig = denoise_wavelet(data, params)
% written by Hyatt Moore IV, March 8, 2012

% initialize default parameters
defaultParams.threshold = 50;
defaultParams.soft_threshold = 1;
defaultParams.num_levels=5;
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
    
    
    
    % wname = 'db1';
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
end
