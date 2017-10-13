function import_prana_events()
%this script was written on June 8, 2011 in order to get Morteza spindle
%data so that he can work on his detection algorithm.
EDF_pathname = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11';
evt_pathname = '/Users/hyatt4/Documents/Sleep Project/Data/events/spindle_scored';
out_evt_pathname= '/Users/hyatt4/Documents/Sleep Project/Data/events/truth';

% #STUDY	epoch.start	epoch.finish
study = cell(10,1);
ranges = cell(10,1);
study{1} = 'A0097_4';
ranges{1} = [207	363];
study{2} = 'A0097_6';
ranges{2} = [23	236];
study{3} = 'A0210_3';
ranges{3} = [63	235];
study{4} = 'A0210_5';
ranges{4} = [22	222];
study{5} = 'A1537_3';
ranges{5} = [53	274];
study{6} = 'A1537_5';
ranges{6} = [22	334];
study{7} = 'C1013_3';
ranges{7} = [130	322];
study{8} = 'C1013_4';
ranges{8} = [160	344];
study{9} = 'R0055_4';
ranges{9} = [70	232];
study{10} = 'R0055_6';
ranges{10} = [63	255];

evtName = 'evt.*.txt';
filenames = dir(fullfile(evt_pathname,evtName));
CHANNEL_INDEX = 3;
for k = 1:numel(filenames)
    
    tic
    x = regexp(filenames(k).name,'evt\.(?<study>.+)\.txt','names');
    study_name = x.study;
    hdr = loadEDF(fullfile(EDF_pathname,[study_name,'.EDF']),CHANNEL_INDEX);
%     [hdr, signal] = loadEDF(fullfile(pathname,[study_name,'.EDF']),CHANNEL_INDEX);
%     C3_channel = signal{1};
    t0 = hdr.T0;
    fs = hdr.fs(CHANNEL_INDEX);
    [t, comments, ~, ~] = parseArtifactsFromFile(fullfile(evt_pathname,filenames(k).name),CHANNEL_INDEX,t0,fs);
    ind = false(size(comments,1),1);
    str2compare = 'CB01';
%      str2compare = 'SW1.spindle.A';
    for n = 1:numel(ind)
%         ind(n)=strcmp('CB01',comments(n,1:4));
        ind(n)=strcmp(str2compare,comments(n,1:numel(str2compare)));
    end;
    events = t(ind,:);
    
    if(~issorted(events(:,1)))
        disp('EVENTS NOT SORTED');
    end
    
    match_ind = find(strcmp(study_name(1:7),study));
    if(~isempty(match_ind))
        
        range = ranges{match_ind};
        range = [(range(1)-1)*30*fs+1,range(2)*fs*30];
    else
        range = [];
    end;

    disp(['file(',num2str(k),')',filenames(k).name,' ',num2str(sum(ind))]);
    if(sum(ind)>0)
        save(fullfile(out_evt_pathname,['evt.',study_name,'.CB_AB']),'events','range');
    end

%     save(fullfile(out_evt_pathname,['evt.',study_name,'.C3-M2.SW1_A_only']),'events');
%     spindles_start_stop=sw1_spindle;
%     save(fullfile(pathname,['_',study_name,'.mat']),'spindles_start_stop','C3_channel');
    toc
end

