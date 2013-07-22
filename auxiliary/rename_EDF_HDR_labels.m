function  rename_EDF_HDR_labels(src_filename,HDR)
%rename labels found in the EDF HDR, as found in HDR if avaialble as
%argument 2
% Written: Hyatt Moore IV
% 10.19.2012

if(exist(src_filename,'file'))
    if(nargin<2)
        HDR= loadHDR(src_filename);
    end
    
    labels.leg.possible = {
        'LAT/RAT'
        'LEG EMG'
        'LLEG1-RLEG1'
        'LLEG1-RLEG2'
        'RLEG1-RLEG2'
        'LLEG2-RLEG1'
        'LLEG2-RLEG2'};
    labels.leg.desired = 'LAT-RAT';
    labels.abd.possible = {'Abd','ABDOMEN'};    
    labels.abd.desired = 'Abdomen';
    labels.airflow.possible = {'AIRFLOW'};    
    labels.airflow.desired = 'Airflow';
    labels.snore.possible = {'SNORE'};    
    labels.snore.desired = 'Snore';
    labels.sao2.possible = {'SAO2'};    
    labels.sao2.desired = 'SaO2';
    
    labels.chin.possible = {'Chin1-Chin2','Chin1-Chin3','Chin3-Chin2'};
    labels.chin.desired = 'Chin EMG';
    labels.ecg.possible = {'EKG1-EKG2'};
    labels.ecg.desired = 'ECG';
    labels.O1.possible = {'O1-AVG','O1-M2'}; %OCC?
    labels.O1.desired = 'O1-x';
    
    %SUM?, RIP-Sum, RIB CAGE, CFLOW?, CPRES, Chest
    %
    labels.position.possible = {'POS','POSITION'};
    labels.position.desired = 'Position';
    
    labels.C3.possible = {'C3-AVG','C3-M2'};
    labels.C3.desired = 'C3-x';
    labels.F3.possible = {'F3-AVG','F3-M2'};
    labels.F3.desired = 'F3-x';
    labels.F4.possible = {'F4-AVG','F4-M2'};
    labels.F4.desired = 'F4-x';
    labels.LEOG.possible = {'L EOG','LEOG-AVG','LEOG-M2','LOC-M2'};
    labels.LEOG.desired = 'LEOG-x';
    labels.REOG.possible = {'R EOG','REOG-AVG','REOG-M1','REOG-M2','ROC-M2'};
    labels.REOG.desired = 'REOG-x';
    
    labels.nasalp.possible = {'NASAL PRESS','NasalP'};
    labels.nasalp.desired = 'NasalPres';
    
    
    types = fieldnames(labels);
    num_types = numel(types);
    new_labels = cell(num_types,1);
    label_index = zeros(num_types,1);
    for t=1:num_types
        cur_type = types{t};
        [~,~,HDR_ind] = intersect(labels.(cur_type).possible,HDR.label);
        if(~isempty(HDR_ind))
            label_index(t) = HDR_ind;
            new_labels{t} = labels.(cur_type).desired;
        end
    end
    new_labels(label_index == 0) = [];
    label_index(label_index == 0) = [];
    relabel_EDF_HDR(src_filename,new_labels,label_index);
else
    fprintf('%s file not found\n',src_filename);
end

