function [out,HRV] = ExtractECGfeatures(HRV,RR,Flagged_samples, params)


% Creating vector of flagged samples with a sampling frequency of 1
HRV.Flagged_samples = zeros(length(HRV.HRV),1)*NaN;
try
for fsn = 1:length(HRV.Stagesamples)
    HRV.Flagged_samples(fsn) = any(Flagged_samples((fsn-1)*params.samplerate+1:fsn*params.samplerate));
end

catch me
    showME(me)
end
HRV.HRV(HRV.Flagged_samples==1) = NaN;

%% HRV features
% Variance
% out.NREM1.var = nanvar(HRV.HRV(HRV.Stagesamples==1));
% out.NREM2.var = nanvar(HRV.HRV(HRV.Stagesamples==2));
% out.NREM3.var = nanvar(HRV.HRV(HRV.Stagesamples==3));
% out.REM.var = nanvar(HRV.HRV(HRV.Stagesamples==5));
out.HRVvar = nanvar(HRV.HRV);
% 
% % Range
% out.NREM1.range = prctile(HRV.HRV(HRV.Stagesamples==1),95)...
%     -prctile(HRV.HRV(HRV.Stagesamples==1),5);
% out.NREM2.range = prctile(HRV.HRV(HRV.Stagesamples==2),95)...
%     -prctile(HRV.HRV(HRV.Stagesamples==2),5);
% out.NREM3.range = prctile(HRV.HRV(HRV.Stagesamples==3),95)...
%     -prctile(HRV.HRV(HRV.Stagesamples==3),5);
% out.REM.range = prctile(HRV.HRV(HRV.Stagesamples==5),95)...
    -prctile(HRV.HRV(HRV.Stagesamples==5),5);
out.HRV05 = prctile(HRV.HRV,5);
out.HRV95 = prctile(HRV.HRV,95);
out.HRVrange = out.HRV95 - out.HRV05;

% Standard deviation FROM the mean
% out.NREM1.SDFM = nanmean(abs(HRV.HRV(HRV.Stagesamples==1)-...
%     nanmean(HRV.HRV(HRV.Stagesamples==1))));
% out.NREM2.SDFM = nanmean(abs(HRV.HRV(HRV.Stagesamples==2)-...
%     nanmean(HRV.HRV(HRV.Stagesamples==2))));
% out.NREM3.SDFM = nanmean(abs(HRV.HRV(HRV.Stagesamples==3)-...
%     nanmean(HRV.HRV(HRV.Stagesamples==3))));
% out.REM.SDFM = nanmean(abs(HRV.HRV(HRV.Stagesamples==5)-...
%     nanmean(HRV.HRV(HRV.Stagesamples==5))));

%% RR features
Flagged_samplenumbers = find(Flagged_samples==1);
if ~isempty(Flagged_samplenumbers)
    fsn = 1;
    while fsn <= length(Flagged_samplenumbers)
        FlagCand = find(RR.RRtime>Flagged_samplenumbers(fsn),1);
        if isempty(FlagCand)
            break
        end
        if Flagged_samplenumbers(fsn)>(RR.RRtime(FlagCand)-...
                RR.RRdur(FlagCand))
            RR.flagged_RR(FlagCand)=1;
        end
        fsn_new = find(Flagged_samplenumbers>RR.RRtime(FlagCand),1);
        if isempty(fsn_new)
            break
        elseif fsn~=fsn_new
            fsn=fsn_new;
        else
            disp(num2str(fsn))
            error('while-loop is stuck - breaking loop')
        end
    end
end

% SDARRhour, standard deviation (averaged over hours)
num_hours = floor(length(HRV.HRV)/3600); % HRV has Fs=1
out.SDRRhour = 0;
for h = 1:num_hours
    out.SDRRhour = out.SDRRhour + ...
        std(RR.RRdur(RR.flagged_RR==0&RR.RRtime>(h-1)*3600*params.samplerate&...
        RR.RRtime<(h*3600*params.samplerate+1)));
end
out.SDRRhour = out.SDRRhour/num_hours;

% SDARR5min, standard deviation (averaged over 5 min periods)
num_periods = floor(length(HRV.HRV)/(60*5)); % HRV has Fs=1
out.SDRR5min = 0;
for p = 1:num_periods
    out.SDRR5min = out.SDRR5min + ...
        std(RR.RRdur(RR.flagged_RR==0&RR.RRtime>(p-1)*(60*5)*params.samplerate&...
        RR.RRtime<(p*(60*5)*params.samplerate+1)));
end
out.SDRR5min = out.SDRR5min/num_periods;

% RMSSD, root mean square of successive differences in RR intervals
RRdiff = RR.RRdur(2:end)-RR.RRdur(1:end-1);
RRdiff = RRdiff(RR.flagged_RR(2:end)==0&RR.flagged_RR(1:end-1)==0);
out.RMSSD = sqrt(mean(RRdiff.^2));
% rms(RRdiff);

% HRV Triangular Index (HRVTI), total number of RR intervals / number of RR
% intervals in modal bin of histogram with binsize = 1/100s
bins = [min(RR.RRdur(RR.flagged_RR==0)):max(RR.RRdur(RR.flagged_RR==0))];
H = hist(RR.RRdur(RR.flagged_RR==0),bins);
out.HRVTI = length(RR.RRdur(RR.flagged_RR==0))/max(H);


