function QRS = detect_QRS(ECG,params)
% DETECT_QRS - Detects the QRS-complexes of a long ECG signal. It does so
% by segmenting the data in 'e_length' second segments and passing them to DETQRS.
%
% QRS = detect_QRS(ECG,Fs), where ECG is the ECG signal and Fs is
% the sampling frequency of the ECG signal. QRS is a vector of zeros,
% with a single sample of value one where QRS complexes are detected
% (in the peak of the R-wave).

% Written by: Emil G.S. Munk, as part of the master thesis project:
% "Automatic Classification of Obstructive Sleep Apnea".

% Filtering signal
ECG = detection.ECG_filter(ECG,params.samplerate);

%% Initiating loop.
L = length(ECG);
epoch_L = params.standard_epoch_sec*params.samplerate;
QRS = zeros(L,1);

% Setting the length behind the window = 4 sec
% (needed for adaptive thresholding).
sl = 4*params.samplerate;
% 'done' keeps track of how much of the signal has already been analysed.
done = 4*params.samplerate+1;

while done < L-epoch_L
    % Passing signal segment to DETQRS.
    [stsamp,QRS_epoch] = detection.detQRS(ECG(done-sl:done+epoch_L-1),params);
    % Cutting QRS as none can be detected in the first 'sl' samples.
    QRS_cut = QRS_epoch(sl+1:stsamp-1);
    % Saving result in the full QRS vector.
    QRS(done:done+length(QRS_cut)-1) = QRS_cut;
    % Saving the index of the last analysed sample.
    done = done+stsamp-sl;
end
