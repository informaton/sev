function detectStruct = detection_rr_simple(channel_cell_data,varargin)
%Based on 1985 paper, " Real-Time QRS Detection Algorithm" by Jiapu Pan and
%Willis Tompkins.  Originally implemented in assembly language this
%algorithm uses a single ECG lead, bandpass filtering (originally cascade
%of high and low-pass filters), derivative filtering, squaring, moving
%integration, and multiple thresholding and adaptation.
%
% This method is lite, and only uses the final, integrated signal.

% Implementation by Hyatt Moore IV
% modified 3/1/2013 - remove global references and use varargin
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.filter_order = 10;
        plist.saveXMLPlist(pfile,params);
    end
end


if(~iscell(channel_cell_data))
    channel_cell_data = {channel_cell_data};
end
data = channel_cell_data{1};
samplerate = params.samplerate;

%% 1. apply bandpass filter
params.bandPass = [5,15]; %5 to 15 he
delay_bp = (params.filter_order)/2;

Bbandpass = fir1(params.filter_order,params.bandPass/samplerate*2);

filtdata = filter(Bbandpass,1,data);

%% apply differentiator
B_diff = 1/8*[-1 -2 0 2 1];
delay_diff = floor(numel(B_diff)/2);
filtdata = filter(B_diff,1,filtdata);

%% square the data
filtdata = filtdata.^2;

%% moving window average/integration
win_sec = 0.15; %this value determined empirically by authors
win_len = ceil(win_sec * samplerate);
B_ma = 1/win_len*ones(1,win_len);
avgdata = filter(B_ma,1,filtdata);

%account for the delay...
delay = delay_diff+delay_bp;
avgdata = [avgdata(delay+1:end); zeros(delay,1)];


%run through the detector for both the filtered and the integrated/averaged
%data/signals

%% Now leaving paper implementation and doing my own thing

epoch_len = 30*samplerate;
num_epochs = ceil(numel(avgdata)/epoch_len);

% thresh = zeros(num_epochs,1);
epoch_range = 1:epoch_len;
% avgpeaks = findpeaks(avgdata);
evt_i = zeros(size(avgdata));
i = 1;
for k=1:num_epochs-1
    thresh = mean(avgdata(epoch_range))*1.5;  
    pkInd = findLocalMaximum(avgdata(epoch_range),thresh);
    numPks = numel(pkInd);
    evt_i(i:(i-1)+numPks)=pkInd+(epoch_range(1)-1); %update indices to reflect the current epoch's offset and store in evt_i
    i = i+numPks;
    epoch_range = epoch_range+epoch_len;
end
%snag the last epoch
epoch_range = epoch_range(1):numel(avgdata);
pkInd = findLocalMaximum(avgdata(epoch_range),thresh);
numPks = numel(pkInd);
evt_i(i:(i-1)+numPks)=pkInd+(epoch_range(1)-1); %update indices to reflect the current epoch's offset and store in evt_i
i = i+numPks;
evt_i = evt_i(1:i-1);

%pick up the last epoch separately, in case it is not 30 seconds like the others


% disp('detection rr_interval');
% toc
%initialize parameters
min_latency_sec = .2;  %minimum physiological time separation between two qrs
Twave_latency_sec = 0.36; %if a peak occurs within this time (and more than min_latencey_sec
                        %then the peak must be checked if it is a T wave
min_latency = min_latency_sec*samplerate;
Twave_latency = Twave_latency_sec*samplerate;

inst_rr = diff([0;evt_i]);
% numAvgPeaks = numel(avgpeaks);
% avgpeakValues = avgdata(avgpeaks);
% numFiltPeaks = numel(filtpeaks);
% filtpeakValues = filtdata(filtpeaks);
1/(mean(inst_rr)/samplerate)*60;


not_hr = inst_rr<min_latency;
possible_twave = find(inst_rr<Twave_latency);
if(possible_twave(1)==1)
    possible_twave(1)=[]; %remove the first one
end
for k=1:numel(possible_twave)
    cur_pk = possible_twave(k);
    if(avgdata(evt_i(cur_pk))<avgdata(evt_i(cur_pk-1))/2) %if the detected pk is less than half the previous qrs, then it is a twave
        not_hr(cur_pk)=true;
    end
end

evt_i = evt_i(~not_hr);
inst_rr = inst_rr(~not_hr);

inst_hr = 1./(inst_rr/samplerate)*60;

%I want to know the difference of heart rate...
B_diff = 1/8*[-1 -2 0 2 1];
delay_diff = floor(numel(B_diff)/2);
diff_hr = filter(B_diff,1,inst_hr);
diff_hr = [diff_hr(delay_diff+1:end); zeros(delay_diff,1)];

sum_order = 4;

delay = (sum_order)/2;
b = ones(sum_order,1);
summed_diff_hr = filter(b,1,diff_hr);
%account for the delay...
summed_diff_hr = [summed_diff_hr((delay+1):end); zeros(delay,1)];

%sympathetic response;
sym = sympthetic_response(inst_hr);


avg_order = 4;

delay = (avg_order)/2;
b = ones(avg_order,1);
avg_hr = filter(b,1,inst_hr)/avg_order;
%account for the delay...
avg_hr = [avg_hr((delay+1):end); zeros(delay,1)];


%use the evt_i referencing vecto to extract the parameters of interest
detectStruct.new_events = repmat(evt_i,1,2);
% detectStruct.paramStruct.avg_rr = avg_rr(evt_i);
% detectStruct.paramStruct.diff_hr = diff_hr; %slope of heart rate
% detectStruct.paramStruct.inst_rr = inst_rr;
detectStruct.paramStruct.inst_hr = inst_hr; %instant heart rate
% detectStruct.paramStruct.avg_hr = avg_hr;
% detectStruct.paramStruct.sympathetic_response = sym; %integrated difference of hr
% detectStruct.paramStruct.summed_diff_hr = summed_diff_hr; %integrated difference of hr
detectStruct.paramStruct.diff_hr = diff_hr; %slope of heart rate
detectStruct.paramStruct.inst_rr = inst_rr;
% mean(detectStruct.paramStruct.avg_rr)/sample_rate*60
% detectStruct.new_data = avgdata;
% new_data = avgdata;

new_data = zeros(size(avgdata));
new_data(1:evt_i(1))=detectStruct.paramStruct.inst_hr(1);
for k=2:numel(evt_i);
   new_data(evt_i(k-1):evt_i(k))=detectStruct.paramStruct.inst_hr(k); 
end

detectStruct.new_data = new_data;



function sym = sympthetic_response(data)
%calculates sympathetic response as follows
% m(n) = mean(n-N1:n);  %normalize by the mean
% sym(n) = [max(n:n+N2)-m(n)]/[min(n-N1:n)-m(n)] 
%
%
beatsBehind = 10;
beatsAhead = 20;
params.order=beatsBehind;
params.rms = 0;
meanData = +filter.filter_ma(data,params); %apply moving averager to get the normalizing mean
params.win_size = beatsBehind;
minData = +filter.nlfilter_min_past(data,params);
params.win_size = beatsAhead;
maxData = +filter.nlfilter_max_future(data,params);

sym = (minData-meanData)./(maxData-meanData);


function pkInd = findLocalMaximum(data,thresh)
%determine local maximum across data that first exceed threshold thresh and
%returns these indices as the vector pkInd
peak_runs = thresholdcrossings(data>thresh);
pkInd = zeros(size(peak_runs,1),1);
for k=1:size(peak_runs,1)
   [~,maxInd] = max( data(peak_runs(k,1):peak_runs(k,2)) );
   pkInd(k) = peak_runs(k,1)-1+maxInd;   
end

function pkInd = mergenearbypeaks(pkInd,ref_data,peak_separation)
%extend area for local peaks and reprocess to get running section of where
%multiple peaks exist in the specificied local area as set in
%peak_separation variable.
peak_runs = thresholdcrossings(diff(pkInd)<peak_separation);

for k=1:size(peak_runs,1)

   [~,maxInd] = max( ref_data(pkInd(peak_runs(k,1)):pkInd(peak_runs(k,2))));
   maxInd = pkInd(peak_runs(k))-1+maxInd;
   pkInd(peak_runs(k,1):peak_runs(k,2))=0; %remove all peak indices in this range
   pkInd(peak_runs(k,1))=maxInd;  %assign the index of the maximum value in this range to one entry
end
pkInd = pkInd(pkInd~=0); %remove zeroed entries
% filtpeak_runs = thresholdcrossings(diff(filtpeaks)<peak_separation);
% avgpeak_runs = thresholdcrossings(diff(avgpeaks)<peak_separation);
% 
% for k=1:size(filtpeak_runs,1)
% 
%    [~,maxInd] = max( filtdata(filtpeaks(filtpeak_runs(k,1)):filtpeaks(filtpeak_runs(k,2))));
%    maxInd = filtpeaks(filtpeak_runs(k))-1+maxInd;
%    filtpeaks(filtpeak_runs(k,1):filtpeak_runs(k,2))=0; %remove all peak indices in this range
%    filtpeaks(filtpeak_runs(k,1))=maxInd;  %assign the index of the maximum value in this range to one entry
% end
% filtpeaks = filtpeaks(filtpeaks~=0); %remove zeroed entries

% for k=1:size(avgpeak_runs,1)
%    [~,maxInd] = max( filtdata(avgpeaks(avgpeak_runs(k,1)):avgpeaks(avgpeak_runs(k,2))));
%    maxInd = avgpeaks(avgpeak_runs(k))-1+maxInd;
%    avgpeaks(avgpeak_runs(k,1):avgpeak_runs(k,2))=0; %remove all peak indices in this range
%    avgpeaks(avgpeak_runs(k,1))=maxInd;  %assign the index of the maximum value in this range to one entry
% end
% avgpeaks = avgpeaks(avgpeaks~=0); %remove zeroed entries

% while(aI<numAvgPeaks&&fI<numFiltPeaks)
%     
%     %% integrated peaks==averaged peaks
%     if(avgpkI<=filtpkI)
%         avgpkVal = avgpeakValues(ai);
%         
%         aI = aI+1;
%         avgpkI = avgpeaks(aI);
%         if(RR_interval>min_latency)  %must physiologically far enough apart before we start looking for another QRS
%             if(avgpkVal>ThreshA1)                
%                 if(RR_interval<Twave_latency)%is it a Twave?
%                     if(avgpkValue<QRSValue/2) %if the peak is less than half the amplitude of the last QRS then it is a Twave
%                         NPKA = 0.125*avgpkVal+0.875*NPKA;
%                     else %we are okay, it is not a Twave.  It is a candidate QRS
%                         SPKA = 0.125*avgpkVal+0.875*SPKA;
%                         candAI = aI;
%                         candAval = avgpkVal;
%                     end
%                 else %not a T-wave, but a candidate QRS
%                     SPKA = 0.125*avgpkVal+0.875*SPKA;
%                     candAI = aI;
%                     candAval = avgpkVal;
%                     
%                 end
%             else %it is noise
%                 NPKA = 0.125*avgpkVal+0.875*NPKA;
%                 if(avgpkVal>TreshA1/2) %may be required later if we don't find a signal
%                     goBackAind=aI;
%                     goBackAval = avgpkVal;
%                 end
%             end
%             
%             %repeat for the other vector...
%             %[NPKF, SPKF, goBackFind, goBackFval] = f(filtpkVal,fI,RR_interval,NPKF, SPKF,
%             %goBackFind, goBackFval,ThreshF1);
%             
%             %do I have a current candidate?//
%             if((candAval||goBackAval)&&(candFval||goBackFval))%these are not zero, and a candidate exists
%                 
%             end
%         end
%     end
%     %% filtered peaks
%     if(filtpki<=avgpkI)
%     end    
%     
%     
% end





