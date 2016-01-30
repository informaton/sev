function detectStruct = detection_arousals_after_hypopnea(source_indices)
%source(1) should be EEG
%source(2) should be NasalPressure
% An arousal after hypopnea is defined here as a significant change in the
% EEG spectrum that occurs between the first 4 seconds of the hypopnea and
% the four seconds immediately after the hypopnea ends
global CHANNELS_CONTAINER;

%nasal air pressure channel
% EEG_channel = CHANNELS_CONTAINER.cell_of_channels{source_indices(1)};
EEG_channel.data = CHANNELS_CONTAINER.getData(source_indices(1));
EEG_channel.sample_rate = CHANNELS_CONTAINER.getSamplerate(source_indices(1));

%% DETECT Hypopneas

[hyp_data,hyp_evts] = detection.detection_hypopnea(source_indices(2));

detectStruct.new_data = hyp_data;
%% DETECT Arousals associated with the detected hypopneas
compare_sec = 4; %compare psd calculated over 4 seconds
compare_len = compare_sec*EEG_channel.sample_rate;

%remove events that would otherwise cause the psd calculation to go beyond
%the number of elements in the study.
hyp_evts = hyp_evts(hyp_evts(:,2)+compare_len<=numel(EEG_channel.data),:);

%optain a matrix of the indices that I am interested in.  
diag_multiplier = triu(ones(compare_len),0);
hyp_start_ind_multiplier = [hyp_evts(:,1),ones(size(hyp_evts,1),compare_len-1)];
hyp_end_ind_multiplier = [hyp_evts(:,2),ones(size(hyp_evts,1),compare_len-1)];


%transpose the product here so that my colon operator (below) will result
%in the correct indexing order into EEG_channel.data
psd_start_ind = (hyp_start_ind_multiplier*diag_multiplier)'; 
psd_end_ind = (hyp_end_ind_multiplier*diag_multiplier)';

%calculate the PSD at the locations associated with each hypopnea event.
psd_hyp_start = calcPSD(EEG_channel.data(psd_start_ind(:)),compare_sec,compare_sec,EEG_channel.sample_rate);
psd_hyp_end = calcPSD(EEG_channel.data(psd_end_ind(:)),compare_sec,compare_sec,EEG_channel.sample_rate);

spectrum = [0.5, 5]; %compare 0 to 5 Hz;
spectrum_ind = round(spectrum/(EEG_channel.sample_rate/size(psd_hyp_start,2)));
spectrum_ind(1) = max(1,spectrum_ind(1)); %do not want 0 index
spectrum_ind = spectrum_ind(1):spectrum_ind(2);

psd_start_spectrum = sum(psd_hyp_start(:,spectrum_ind),2);
psd_end_spectrum = sum(psd_hyp_end(:,spectrum_ind),2);

threshold = 10;  %arousal if greater than 10 times the density
detectStruct.new_events = hyp_evts(psd_end_spectrum./psd_start_spectrum>threshold,:);
detectStruct.paramStruct = [];
