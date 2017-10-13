function detectStruct = detection_ecg_wxcc(channel_index,optional_params)
% function detectStruct = detection_ecg_wxcc(data, optional_params)
%weighted cross correlation coefficient method 

global CHANNELS_CONTAINER;


% channel_obj = CHANNELS_CONTAINER.cell_of_channels{channel_index};
channel_obj.data = CHANNELS_CONTAINER.getData(channel_index);
channel_obj.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);
% channel_obj.sample_rate = 100;


% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = '+detection/detection_ecg_wxcc.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        
        params.med_filter_order_sec = 0.255;
        plist.saveXMLPlist(pfile,params);
        
        
    end
end

med_order = ceil(params.med_filter_order_sec*channel_obj.sample_rate);
BLKSIZ = 60*100; %2 minutes as 100 samples per second
tic
data = channel_obj.data;
data = abs(data-mean(data));
if(BLKSIZ*10 < numel(channel_obj.data))
    data = medfilt1(data,med_order,BLKSIZ);  %use a for loop to compute median filter at intervals of BLKSIZ (save memory at computation cost)
else
    data = medfilt1(data,med_order);
end

% data = data-mean(data(:));
toc
% segment_samples_size = 0.3*channel_obj.sample_rate;
% before = ceil(segment_samples_size/2);
% after = segment_samples_size - before;

qrs_detection_thresh_start = 0.6;
qrs_detection_thresh_stop = 0.3;

template_dur_sec = 6;
template_dur_samples = floor(template_dur_sec*channel_obj.sample_rate)+1;
reinitialize_after_dur_samples = 60*5*channel_obj.sample_rate;  %reinitialize the QRS template every 5 minutes; -> try 15 minutes
next_reinit = reinitialize_after_dur_samples;
QRS_template = [];
%preallocate for speed:
%estimate 200 bpm as worst possible case
bpm_max = 200;
qrs_vector = zeros(numel(data)/channel_obj.sample_rate/60*bpm_max,1);
qrs_count = 0;
k = 0;
while(k<numel(data)-template_dur_samples)
    k = k+1;
    if(isempty(QRS_template)||k>=next_reinit)
        QRS_template = init_QRS_template(data(k:k+template_dur_samples),channel_obj.sample_rate);
        QRS_template_sqrd= QRS_template(:)'*QRS_template;
        k = k+template_dur_samples;  %jump to the next candidate sampling area
        next_reinit = k+reinitialize_after_dur_samples;
        QRS_size_range = 1:numel(QRS_template);
    else
        range = QRS_size_range+k;        
        WXCC = calcWXCC(QRS_template,data(range),QRS_template_sqrd);
        if(WXCC>qrs_detection_thresh_start)
            start_k = k;
            while(WXCC>=qrs_detection_thresh_stop && (k<numel(data)-template_dur_samples))
                k=k+1;
                range = QRS_size_range+k;  
%                 try
                WXCC = calcWXCC(QRS_template,data(range),QRS_template_sqrd);
%                 catch ME
%                    ME 
%                 end
            end
            end_k = k;
%             [~,peak_ind] = max(data(start_k:end_k));
            [~,peak_ind] = max(abs(channel_obj.data(start_k:end_k)));
            peak_k = start_k+peak_ind;
            range = QRS_size_range+peak_k;
            cand_qrs = data(range);
            
            %update by 3/4 of template and 1/4 of current candidate qrs
            %that was selected...
            QRS_template = QRS_template*0.75+cand_qrs*0.25;
            qrs_count = qrs_count+1;
            qrs_vector(qrs_count) = peak_k;
        end;
    end
end

qrs_vector = qrs_vector(1:qrs_count); % a vector of indices that represent peaks in the qrs.
detectStruct.new_data = data;
detectStruct.new_events = [qrs_vector,qrs_vector];
detectStruct.paramStruct = [];
toc
end

function QRS_template = init_QRS_template(data,sample_rate)
%data is six seconds of data to be used for QRS template
%sample_rate is the sample rate of data
%the first 6-s sequence of the ECG is rectified, and maxima are chosen
%such that each is followed by 0.35 s during which no larger value occurs.
%The maxima are ranked by size, and the WXCC is calculated between the
%0.3-s segment of nonrectified signal centered around the largest maximum
%and the corresponding segment centered around each of the other maxima in
%descending order.  This process is repeated for all maxima or until WXCC
%values greater than 0.7 are obtained between one segment and any two
%others.  
% The initial template is formed from the average of these three segments
% by truncating all tail values with magnitudes below 10% of the maximum
% value.  Adiitional points may be trunctated or re-introduced at each end
% to ensure that the trial template is between 0.1s and 0.22s in length.

% dur_sec = 6;
% dur_samples = floor(dur_sec*sample_rate)+1;
% rect_data = abs(data(1:dur_samples));
rect_data = abs(data);
maxima_dur_sec = 0.35;
maxima_dur_samples = floor(maxima_dur_sec*sample_rate)+1;
maxima_ind = findpeaks(rect_data);
good_maxima_ind = true(size(maxima_ind));

%the first 6-s sequence of the ECG is rectified, and maxima are chosen
%such that each is followed by 0.35 s during which no larger value occurs.
for k = 1:numel(maxima_ind)-1
    maxima_subset_ind = maxima_ind(k+1:end);
    remain_diff = maxima_subset_ind-maxima_ind(k);
    if(~isempty(remain_diff)&&...
            any(rect_data(maxima_subset_ind(remain_diff<=maxima_dur_samples))...
            >=rect_data(maxima_ind(k))))
        good_maxima_ind(k) = false;
    end
end

%take the ones that are good - i.e. passed the above test
maxima_ind = maxima_ind(good_maxima_ind);

%The maxima are ranked by size, and the WXCC is calculated between the
%0.3-s segment of nonrectified signal centered around the largest maximum
%and the corresponding segment centered around each of the other maxima in
%descending order.  This process is repeated for all maxima or until WXCC
%values greater than 0.7 are obtained between one segment and any two
%others.
QRS_template = [];
qrs_thresh = 0.8;  %this is set higher for template initialization
%get the before and after range of the mid point that will be used for qrs
%consideration
segment_samples_size = 0.3*sample_rate;
before = ceil(segment_samples_size/2);
after = segment_samples_size - before;
qrs_matrix = zeros(numel(maxima_ind));
[~, maxima_ind_descending] = sort(rect_data(maxima_ind),'descend');
maxima_ind = maxima_ind(maxima_ind_descending);
maxima_ind = maxima_ind(maxima_ind>segment_samples_size & maxima_ind< (numel(data)-segment_samples_size));


for k =1:numel(maxima_ind)
    for j=k:numel(maxima_ind)
        
        current_sample = maxima_ind(j);
        current_range = (-before:after)+current_sample;
        if j==k
            %candidate QRS
            cand_QRS = data(current_range);
            cand_QRS_sqrd = cand_QRS(:)'*cand_QRS(:);
        else
            if(qrs_matrix(k,j)==0)
                cur_QRS = data(current_range);
                qrs_matrix(k,j) = calcWXCC(cand_QRS,cur_QRS,cand_QRS_sqrd);
                qrs_matrix(j,k) = qrs_matrix(k,j); %prevents possible duplication of effort later on
            end
        end
    end
    
    if(sum(qrs_matrix(k,:)>qrs_thresh)>=2)
        % The initial template is formed from the average of these three segments
        % by truncating all tail values with magnitudes below 10% of the maximum
        % value.  Adiitional points may be trunctated or re-introduced at each end
        % to ensure that the trial template is between 0.1s and 0.22s in length.
        [~,cols] = sort(qrs_matrix(k,:),'descend'); %grab the columns that broke the threshold the most
        
        maxima_ind = maxima_ind([k,cols(1:2)]);
        
        QRS_template = zeros(size(cur_QRS));
        
        for c = 1:numel(maxima_ind)
            current_range = (-before:after)+maxima_ind(c);
            QRS_template =  QRS_template+data(current_range)/3;
        end
        max_val = max(abs(data(maxima_ind)));
        
        trunc_template_ind = find(abs(QRS_template)>max_val/10);
        
        template_size =ceil([0.1 0.22]*sample_rate);

        if(numel(trunc_template_ind)<2)
%             trunc_template_ind = [1,template_size(2)]; %catch possible error
        else
            trunc_template_ind = [trunc_template_ind(1), trunc_template_ind(end)]; %get the indices of the tails that are below 10% of the maximum value
        end;
        siz_ = diff(trunc_template_ind)+1;

        if(siz_<template_size(1) || siz_>template_size(2))

            %it is too short - this is a positive signed result
            if(siz_<template_size(1))

                segment_samples_size = template_size(1);
%                 diff_siz = template_size(1)-siz_;
                
                %it is too long - this is a negative signed result
            else
                segment_samples_size = template_size(2);
%                 diff_siz = template_size(2)-siz_;
            end
%             segment_samples_size = segment_samples_size - diff_siz;
            midpoint = ceil(maxima_dur_samples/2);
            before = ceil(segment_samples_size/2);
            after = segment_samples_size - before;
            trunc_template_ind = [-before,after]+midpoint;

%             more_before = ceil(diff_siz/2);
%             more_after = diff_siz-more_before;
%             trunc_template_ind = [trunc_template_ind(1)+more_before,trunc_template_ind(2)+more_after];
        end
        QRS_template = QRS_template(trunc_template_ind(1):trunc_template_ind(2));
        
        break;
    end
end
end





function WXCC = calcWXCC(signal_template,signal_comparison,template_sqrd)
    comparison_sqrd= signal_comparison(:)'*signal_comparison(:);
    inner_prod = signal_template(:)'*signal_comparison(:);
    if(template_sqrd>=comparison_sqrd)
        WXCC = inner_prod/template_sqrd;
    else
        WXCC = inner_prod/comparison_sqrd;
    end

end
