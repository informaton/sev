%> @file nlfilter_ani
%> @brief Calculates the Analgesia-Nociception-Index (ANI) as described by 
%> PhysioDoloris: a monitoring device for Analgesia / Nociception balance
%> evaluation using Heart Rate Variability analysis.
%======================================================================
%> @brief 
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> @retval filtSig The filtered signal. 
%> written by Hyatt Moore IV, December 3, 2015

%> @note Requires heart rate detection classification method,
%> interpoliation or spline, and wavelet decomposition filtering methods:
%> -
%> - 
%> - 
function filtSig = nlfilter_ani(sigData, params)
    
    % initialize default parameters
    
    defaultParams.freqStart_Hz = 0.15;
    defaultParams.freqStop_Hz = 0.5;    
    defaultParams.filter_order = 10;  %ECG filter
    defaultParams.normalized_samples_per_second = 4;  %
    defaultParams.duration_area_under_envelope_for_ani_seconds = 16;
    
    % return default parameters if no input arguments are provided.
    if(nargin==0)
        filtSig = defaultParams;
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
        
        stageStruct = [];
        nn_params = params;
        % Get normalized n.n signal
        detectStruct = detection.detection_nn_simple(sigData,nn_params, stageStruct);
        sigData = detectStruct.new_data(:);  %work with row vectors
        
        
        %alternatively, use emil's HRV method ...
        params.nlfilter_hrv.upperThreshold = 1.2;
        params.nlfilter_hrv.lowerThreshold = 0.8;
        params.nlfilter_hrv.samplerate = params.samplerate;
        % sigData = filter.nlfilter_hrv(sigData, params.nlfilter_hrv);
        
        % wavelet filter for the interval of interest:
        max_decompositions = 10;
        waveletParams.wname = 'db4';
        waveletParams.threshhold = 50;
        waveletParams.num_levels = 5;
        waveletParams.soft_threshhold = 1;
        waveletParams.decomposition_levels = true(max_decompositions);
        waveletParams.approximation_level = true;
        waveletParams.samplerate = params.samplerate;
        
        % or just use a convential filter
        bandPassParams.order=40;
        bandPassParams.samplerate = params.samplerate;
        bandPassParams.start_freq_hz=defaultParams.freqStart_Hz;
        bandPassParams.stop_freq_hz=defaultParams.freqStop_Hz;
        
        
        
        %filterParams = bandPassParams;
        filtSig = filter.fir_bp(sigData, bandPassParams);
        %filtSig = sigData;
        envelopeHeightSig = getEnvelopeHeight(filtSig);        
        numSeconds = params.duration_area_under_envelope_for_ani_seconds;
        movingSummerParams.order = numSeconds*params.samplerate;
        movingSummerParams.abs = 0;

        aucSig = filter.filter_ma(envelopeHeightSig(:), movingSummerParams);
                
%         aucSig1 = filter.filter_qma(envelopeHeightSig(:), movingSummerParams);
%         
%         aucSig2 = filter.filter_movsum(envelopeHeightSig(:), movingSummerParams)/movingSummerParams.order;

        
        %         aucMin = aucSig;
        %         aniSig = 100*(alpha*aucMin+beta)/somethingElse;
        
        aniSig = aucSig;  %/max(aucSig)*100;
        filtSig = aniSig;
    end
end

%calculate the upper and lower envelopes  
function aueSig = getEnvelopeHeight(sigData)
    [upperEnvelope, lowerEnvelope] = getSignalEnvelope(sigData);
    aueSig = abs(upperEnvelope - lowerEnvelope);  % determine the distance between upper and lower envelope at each sample
end

function [upperEnvelope, lowerEnvelope] = getSignalEnvelope(sigData)
    xx=1:numel(sigData);
    
    upperPeakIndices = sev_findpeaks(sigData);
    upperPeakValues = sigData(upperPeakIndices);
    upperEnvelope = spline(upperPeakIndices,upperPeakValues,xx);
    
    lowerPeakIndices = sev_findpeaks(-sigData);   
    lowerPeakValues = sigData(lowerPeakIndices);
    lowerEnvelope = spline(lowerPeakIndices,lowerPeakValues,xx);
end