%> @file decompose_wavelet.cpp
%> @brief Decompose signal into wavelets.
%> @param data Input signal.
%> @param params Structure of field/value parameter pairs that to adjust filter's
%> behavior.  Fields include:
%> - @c wname
%> - @c threshold
%> - @c num_levels
%> - @c soft_threshold
%> - @c decomposition_levels
%> - @c approximation_level
%> @retval The recomposition of the filtered wavelet decomposition of the
%> input signal (data).
%> @note Use wavelet_dlg (from SEV) to edit these parameters.
%> @note written by Hyatt Moore IV, November, 20'ish, 2012
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
%> @note modified 9/24/2014 - removed antiquated global reference.
function filtsig = decompose_wavelet(data, params)
% written by Hyatt Moore IV, November, 20_ish 2012


% initialize default parameters
max_decompositions = 10;
defaultParams.wname = 'db1';
defaultParams.threshhold = 50;
defaultParams.num_levels = 5;
defaultParams.soft_threshhold = 1;
defaultParams.decomposition_levels = true(max_decompositions);
defaultParams.approximation_level = true;
% return default parameters if no input arguments are provided.
if(nargin==0)
    filtsig = defaultParams;
else
    
    if(nargin<2 || isempty(params))
        
        matfile = fullfile(fileparts(mfilename('fullpath')),'decompose_wavelet.mat');
        
        if(exist(matfile,'file'))
            %load it
            mStruct= load(matfile);
            params = mStruct.params;
        else
            
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
end


