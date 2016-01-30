function detectStruct = detection_rr_interval(channel_index,optional_params)
%Based on 1985 paper, " Real-Time QRS Detection Algorithm" by Jiapu Pan and
%Willis Tompkins.  Originally implemented in assembly language this
%algorithm uses a single ECG lead, bandpass filtering (originally cascade
%of high and low-pass filters), derivative filtering, squaring, moving
%integration, and multiple thresholding and adaptation.

global CHANNELS_CONTAINER;
% tic
DEBUG=0;
if(DEBUG)
    data = channel_index;
    sample_rate = 100;
else
    data = CHANNELS_CONTAINER.getData(channel_index);
    sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);
end

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = '+detection/detection_rr_interval.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.filter_order = 10;
        plist.saveXMLPlist(pfile,params);
    end
end


%% 1. apply bandpass filter
params.bandPass = [5,15]; %5 to 15 he
delay_bp = (params.filter_order)/2;

Bbandpass = fir1(params.filter_order,params.bandPass/sample_rate*2);

filtdata = filter(Bbandpass,1,data);

%% apply differentiator
B_diff = 1/8*[-1 -2 0 2 1];
delay_diff = floor(numel(B_diff)/2);
filtdata = filter(B_diff,1,filtdata);

%% square the data
filtdata = filtdata.^2;

%% moving window average/integration
win_sec = 0.15; %this value determined empirically by authors - and adjusted by me
win_len = ceil(win_sec * sample_rate);
B_ma = 1/win_len*ones(1,win_len);
avgdata = filter(B_ma,1,filtdata);
% win_sec_long = 0.15; %this value determined empirically by authors - and adjusted by me
% win_len_long = ceil(win_sec_long * sample_rate);
% B_ma = 1/win_len_long*ones(1,win_len_long);
% avgdata = filter(B_ma,1,filtdata);
% 
% win_sec_short = 0.05;
% win_len_short = ceil(win_sec_short * sample_rate);
% B_ma = 1/win_len_short*ones(1,win_len_short);
% filtdata = filter(B_ma,1,filtdata);

%account for the delay...
delay = delay_diff+delay_bp;
filtdata = [filtdata(delay+1:end); zeros(delay,1)];
avgdata = [avgdata(delay+1:end); zeros(delay,1)];

%run through the detector for both the filtered and the integrated/averaged
%data/signals

filtpeaks = findpeaks(filtdata);
avgpeaks = findpeaks(avgdata);


% disp('detection rr_interval');
% toc
%initialize parameters
min_latency_sec = .2;  %minimum physiological time separation between two qrs
Twave_latency_sec = 0.36; %if a peak occurs within this time (and more than min_latencey_sec
                        %then the peak must be checked if it is a T wave
min_latency = min_latency_sec*sample_rate;
Twave_latency = Twave_latency_sec*sample_rate;

% numAvgPeaks = numel(avgpeaks);
% avgpeakValues = avgdata(avgpeaks);
% numFiltPeaks = numel(filtpeaks);
% filtpeakValues = filtdata(filtpeaks);


%initialize thresholds
SPKA = 0;
NPKA = 0;
ThreshA1 = 0;
% ThreshA2 = 0;
SPKF = 0;
NPKF = 0;
ThreshF1 = 0;
% ThreshF2 = 0;

lastQRSi = 1;  %index of last QRS found
numQRStracked = 8;
% QRSTracker = zeros(1,numQRStracked); %keep track of the last 8 qrs locations
RR_tracker = repmat(sample_rate,1,numQRStracked);% keep track of last 8 RR intervals ->initialize to a 60beatsperminute RR interval /i.e. one a second
RR_trackI = 0;
RR2_tracker = RR_tracker;  %keeps track of the last 8 RR intervals that fall within a certain limit
RR2_trackI = 0;

%interval limits
RR2_AVG = mean(RR2_tracker);
RR_LOW = 0.92*RR2_AVG;
RR_HIGH = 1.16*RR2_AVG;
RR_MISSED = 1.66*RR2_AVG;

% avgpkI = avgpeaks(aI);
% filtpkI = filtpeaks(fI);

RR_count = 0;
%indices of peaks that match on both the filtered and smoothed data
%which is an interpreted requirement of QRS classification
pkInd = intersect(avgpeaks,filtpeaks); 

% pkInd = avgpeaks;
% filtdata = avgdata;
% peak_separation = 2; %merge peaks within .05 seconds of each other and get the largest
% pkInd = mergenearbypeaks(pkInd,avgdata,peak_separation);


updateRR = false;  %boolean flag for when the RR ranges need to be updated
lookBackInd = 0;
avg_rr = zeros(size(pkInd));
rr = zeros(size(pkInd));
evt_i= false(size(pkInd));  %indexing vector to know where to store valid events
numPks = numel(pkInd);
lookBackK = 1;
k=1;
OkayToUpdateSPK = true; %hack to get around the case where we find a T-wave..
while(k<=numPks)
    pkI = pkInd(k);
    RR_interval = pkI-lastQRSi+1;
    avgpkVal = avgdata(pkI);
    filtpkVal = filtdata(pkI);
    
    if(RR_interval>min_latency)  %must physiologically far enough apart before we start looking for another QRS
        if(avgpkVal>ThreshA1 && filtpkVal>ThreshF1)
            %if it is too soon, it may be a Twave
            if(RR_interval<Twave_latency)
                if(avgpkVal<avgdata(lastQRSi)/2) %if the maximal slope (peak of filtered signal) is less than half the amplitude of the last QRS then it is a Twave
                    %calculation for T-wave noise is done below with other
                    %
                    OkayToUpdateSPK=false;
                     NPKA = 0.125*avgpkVal+0.875*NPKA; %the current part is noise
                     NPKF = 0.125*filtpkVal+0.875*NPKF; %we have noise
                else %we are okay, it is not a Twave.  It is a candidate QRS
                    QRSi=pkI;
                end
            else %not a T-wave, but our QRS
                QRSi=pkI;
            end
        elseif(avgpkVal>ThreshA1/2 && filtpkVal>ThreshF1/2)
            lookBackInd = pkI; 
            lookBackK = k;
        end
        if(QRSi) %did we find something?
            SPKA=0.125*avgpkVal+0.875*SPKA;
            SPKF= 0.125*filtpkVal+0.875*SPKF;
            lastQRSi = QRSi;
            updateRR = true;
        elseif((lookBackInd~=0)&&(RR_interval>RR_MISSED))
            lastQRSi = lookBackInd;
            SPKA=0.25*avgdata(lastQRSi)+0.75*SPKA;
            SPKF=0.25*filtdata(lastQRSi)+0.75*SPKF;     
            updateRR = true;
            k=lookBackK;
            OkayToUpdateSPK=true;

        elseif(OkayToUpdateSPK)
            if(avgpkVal>ThreshA1)
                SPKA=0.125*avgpkVal+0.875*SPKA;
            else
                NPKA = 0.125*avgpkVal+0.875*NPKA;
            end
            if(filtpkVal>ThreshF1)
                SPKF=0.125*filtpkVal+0.875*SPKF;
            else
                NPKF = 0.125*filtpkVal+0.875*NPKF;
            end
        else
            OkayToUpdateSPK=true;
        end

        %update the running rr intervals
        if(updateRR)            
            updateRR=false;
            RR_count = RR_count+1;
            RR_trackI = mod(RR_trackI,numQRStracked-1)+1; %produces an index between 1 and numQRStracked (i.e. 8)
            RR_tracker(RR_trackI) = RR_interval;
            RR_trackI = RR_trackI+1;
            if(RR_interval>RR_LOW && RR_interval<RR_HIGH)
                RR2_trackI = mod(RR2_trackI,numQRStracked-1)+1;
                RR2_tracker(RR2_trackI) = RR_interval;
                RR2_avg = mean(RR2_tracker);
                RR2_trackI = RR2_trackI+1;
                RR_LOW = 0.92*RR2_avg;
                RR_HIGH = 1.16*RR2_avg;
                RR_MISSED = 1.66*RR2_avg;
            end
            RR_AVG1 = mean(RR_tracker); %I could update the RR interval here and output as an event parameter?
            evt_i(k)=true;
            avg_rr(k) = RR_AVG1;
            rr(k) = RR_interval;
%             ThreshA1 = NPKA+0.25*(SPKA-NPKA);
%             ThreshF1 = NPKF+0.25*(SPKF-NPKF);
%             if(lookBackInd==QRSi)
%                 ThreshA1 = ThreshA1/2;
%                 ThreshF1 = ThreshF1/2;
%             else
%                 ThreshA1 = NPKA+0.25*(SPKA-NPKA);
%                 ThreshF1 = NPKF+0.25*(SPKF-NPKF);
%             end

            lookBackInd = 0;
            QRSi = 0;

         
        else
%             NPKA = 0.125*avgpkVal+0.875*NPKA;
%             NPKF = 0.125*filtpkVal+0.875*NPKF;
        end
%         ThreshA1 = NPKA;
%         ThreshF1 = NPKF;
%          ThreshA1 = .75*NPKA+0.25*(SPKA-NPKA);
%          ThreshF1 = 0.75*NPKF+0.25*(SPKF-NPKF);
         ThreshA1 = NPKA+0.25*(SPKA-NPKA);
         ThreshF1 = NPKF+0.25*(SPKF-NPKF);

    end
    k=k+1;
end
RR_count/500
% toc

%use the evt_i referencing vecto to extract the parameters of interest
detectStruct.new_events = repmat(pkInd(evt_i),1,2);
detectStruct.paramStruct.avg_rr = avg_rr(evt_i);
detectStruct.paramStruct.inst_rr = rr(evt_i);

mean(detectStruct.paramStruct.avg_rr)/sample_rate*60
mean(detectStruct.paramStruct.inst_rr)/sample_rate*60

detectStruct.new_data = avgdata;

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





