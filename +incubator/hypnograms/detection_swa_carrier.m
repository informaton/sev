function detectStruct = detection_swa_carrier(source_index)
%Slow Wave activity (SWA) automated detector as presented in Julie
%Carrier's paper, "Sleep slow wave changes during the middle years of
%life." - published in 2011 in the European Journal of Neuroscience
%source_index = EEG channel
%
%Slow waves defined as SW < 4Hz and > 75uV
%Slow-wave Activity is 0.5-4.5Hz during non-rem
% it is a classic measure of sleep intensity (i..e more time awake produces
% higher SWA, whereas more time asleep produces lower SWA)

%bug report 1:
%found possible problem with duplicate start sample entries occuring - this
%occured in file A0097_4 .EDF during epoch 36, stage wake/0
% with start sample 106150 and stop sample 106349
%apparently two different values for B were found, but the maximum of the
%two was not taken, it must have gone up and come down and then gone up
%again - 
% this issue has not been investigated further as it was found during
%database entry processing and caused a problem due to the duplicate entry
% bug entry date: 1/4/12

%The steps:
%1. Bandpass filter data between 0.3-4.0Hz (-3db [0.3, 4] and -23 dB [0.1
%4.2])
%2. Remove artifact data using Brunner method
%3. Detect SW using four criteria (Massimini et al., 2004; Dang-vu et al., 2008)
%    i.   negative peak < - 40uV
%    ii.  peak-to-peak amplitude > 75 uV
%    iii. duration of negative deflection between (125 ms, 1500 ms)   
%    iv.  duration of positive deflection < 1 s 

%             B
%             __
%            /  \
%           /    \      E /\
% 0uV----++/A+++++\C++++ /++-----
%        \/         \   /
%                    \_/
%                     D
%
% SW Characteristics:
%  a. SW Frequency: number of cycles per second
%  b. SW amplitude: difference in voltage between B and D
%  c. SW negative phase duration (time(s) between A and C
%  d. SW positive phase duration (time between C and E
%  e. SW slope between B and D (uV/sec)

global CHANNELS_CONTAINER;

% EEG_channel = CHANNELS_CONTAINER.cell_of_channels{source_index};
EEG_channel.data = CHANNELS_CONTAINER.getData(source_index);
EEG_channel.sample_rate = CHANNELS_CONTAINER.getSamplerate(source_index);

%% Detection criteria
neg_min_peak = -40; %minimum negative peak
p2p_min_amp = 75; %minimum peak to peak amplitude
neg_deflection_minmax_dur_sec = [.125 1.5]; %duration range in seconds for negative deflection
neg_deflection_range = round(neg_deflection_minmax_dur_sec*EEG_channel.sample_rate);
neg_phase_search_range = 0:neg_deflection_range(end)-1;

pos_deflection_max_dur_sec = 1; %max duration of positive deflection in seconds
pos_phase_search_range = 1:ceil(pos_deflection_max_dur_sec*EEG_channel.sample_rate)-1;

%1. LPF the channel
SWA_DLG.order = 20;
SWA_DLG.w = [.3 4];
n = SWA_DLG.order;
delay = (n)/2;
b = fir1(n,SWA_DLG.w/EEG_channel.sample_rate*2);

SWA_line = filter(b,1,EEG_channel.data);

%account for the delay...
SWA_line = [SWA_line(delay+1:end); zeros(delay,1)];


%2.  REmove artifacts - using BRUNNER.  (this step is skipped here, but
%data can be removed later using artifact detector)

%% 3.  Find SWA events

%critera 1: minimum negative value
peaks = findvalleys(SWA_line);
min_pks = find(SWA_line(peaks)<neg_min_peak);
%this step removes any plateus, and takes the last value found at the platue.  

if(isempty(min_pks))
    num_pks = 0;
else
    min_pks_ind = diff([min_pks; min_pks(end)])~=1;
    min_pks_ind = peaks(min_pks(min_pks_ind));
    
    num_pks = numel(min_pks_ind);
    event_indices = zeros(num_pks,5); %store indices A-E

end

num_events = 0;

%now go through each one and determine if other criteria are met or not.  
for k = 1:num_pks
    cur_pk_ind = min_pks_ind(k);
    B_ind = cur_pk_ind;
    
    %find A and C next
    %criteria 3: negative phase duration
    start_search_range = cur_pk_ind - fliplr(neg_phase_search_range);
    %don't take events that start before the study begins
    if(start_search_range(1)>0)
        A_ind = find(SWA_line(start_search_range)>=0,1,'last');
        if(~isempty(A_ind))
            A_ind = start_search_range(A_ind);
            center_search_range = A_ind+1+neg_phase_search_range; 
            %or center_search_range = B_ind + neg_phase_search_range;
            
            %don't go beyond the length of the study
            if(center_search_range(end)<=numel(SWA_line))
                C_ind = find(SWA_line(center_search_range)>=0,1);
            
                if(~isempty(C_ind))
                    C_ind = center_search_range(C_ind);
                    neg_dur = C_ind - A_ind; %negative phase duration
                    
                    %criteria 3: min max duration of negative deflection            
                    if(neg_dur > neg_deflection_range(1) && neg_dur < neg_deflection_range(end))
                        end_search_range = C_ind + pos_phase_search_range;
                        if(end_search_range(end)<=numel(SWA_line))                            
                            D_ind = findpeaks(SWA_line(end_search_range));
                            if(~isempty(D_ind))
                                D_ind = end_search_range(D_ind);
                                [max_peak,max_ind] = max(SWA_line(D_ind));
                                D_ind = D_ind(max_ind);
                                if(max_peak-SWA_line(B_ind)>p2p_min_amp)
                                    E_search_range = D_ind:end_search_range(end);
                                    E_ind = find(SWA_line(E_search_range)<=0,1);
                                    if(~isempty(E_ind))
                                        E_ind = E_search_range(E_ind);
                                        num_events = num_events+1;
                                        event_indices(num_events,:) = [A_ind, B_ind, C_ind, D_ind, E_ind];
                                        

                                    end;                                    
                                end                                
                            end                    
                        end                        
                    end
                end
            end
        end
    end

end

event_indices = event_indices(1:num_events,:);
detectStruct.new_events = event_indices(:,[1,5]); %[A(:),E(:)]
detectStruct.new_data =  SWA_line;

%get the parameters now for the qualifying events
paramStruct.freq = (EEG_channel.sample_rate./diff(detectStruct.new_events'))'; %-this is 1/duration_sec - the longer the duration, the slower the wave here = if it is 100 samples, then it is 1Hz (fs =100), if it is 200 samples (2seconds), then it is 0.5Hz
paramStruct.amplitude = EEG_channel.data(event_indices(:,4))-EEG_channel.data(event_indices(:,2)); %data(B)-data(D)
paramStruct.neg_phase_dur_sec = diff(event_indices(:,[1,3])')'/EEG_channel.sample_rate;
paramStruct.pos_phase_dur_sec = diff(event_indices(:,[3,5])')'/EEG_channel.sample_rate;
paramStruct.pk2pk_slope_uVperSec = paramStruct.amplitude./(diff(event_indices(:,[2,4])')'/EEG_channel.sample_rate);
%             B
%             __
%            /  \
%           /    \      E /\
% 0uV----++/A+++++\C++++ /++-----
%        \/         \   /
%                    \_/
%                     D
%
% SW Characteristics:
%  a. SW Frequency: number of cycles per second
%  b. SW amplitude: difference in voltage between B and D
%  c. SW negative phase duration (time(s) between A and C
%  d. SW positive phase duration (time between C and E
%  e. SW slope between B and D (uV/sec)



detectStruct.paramStruct = paramStruct;

