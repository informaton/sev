function REMmetrics = calculateREMmetrics(mat_events_epoch_cycle, stage_dur_hour,mat_resp,sample_rate,key, plm_params,respiratoryRemovalType)
%mat_events_epoch - 3 column matrix of predicted leg movements (start,
%stop, epoch)
%mat_resp - 2 column matrix of respiratory events to be removed
%REMmetrics is a structure with the following fields
%     REMmetrics.periodicity = periodicity_results;
%     REMmetrics.hrs_evaluated = stage_dur_hour;
%     REMmetrics.attrition_strength = strength_attrition_results;
%     REMmetrics.attrition_plm = plm_attrition_results;
%     REMmetrics.strength =strength_results;
%     REMmetrics.PLMI = PLMI_results;
%     REMmetrics.HR_delta = change in heart rate from min to max
%     REMmetrics.HR_slope = slope of heart rate change

% Written by Hyatt Moore IV
% for collaboration with VA on December 5, 2012
if(nargin==0)
    REMmetrics.emcount = [];
    REMmetrics.strength = [];
    REMmetrics.attrition_em_by_hour = [];
    REMmetrics.attrition_em_by_cycle = [];
    REMmetrics.hrs_evaluated = [];
else
    REMmetrics = [];
    mat_predictor = mat_events_epoch_cycle(:,1:2);
    predictor_epochs = mat_events_epoch_cycle(:,3);
    predictor_cycles = mat_events_epoch_cycle(:,4);
    if(nargin<7)
        respiratoryRemovalType = 'both';
    end    
    if(nargin>2 && ~isempty(mat_resp) && ~strcmpi(respiratoryRemovalType,'none'))
        [mat_predictor,held_indices] = removeOverlappingRespiratoryEvents(mat_predictor,mat_resp,respiratoryRemovalType);
        plm_params = plm_params(held_indices);
    end
    
    LM_count = size(mat_predictor,1); %number of rows available
    
    if(LM_count>2) %otherwise, may have a divide by 0 for ferri's periodicity calculation
        lm_struct.new_events = mat_predictor;
        plm_struct = calculatePLMstruct(lm_struct,sample_rate);
        params = plm_struct.paramStruct;
        
        %plmi
        if(stage_dur_hour>0)
            %                         [paramCell{:}] = params.meet_AASM_PLM_criteria;
            %                         paramMat = cell2mat(paramCell);
            %                         PLM_ind = paramMat;
            % PLM_count = sum(paramMat);
            PLM_ind = params.meet_AASM_PLM_criteria; %a logical vector
            
            PLM_count = sum(PLM_ind);
            PLMI_results = PLM_count/stage_dur_hour;
            
            %strength - plm/series
            %                         [paramCell{:}] = params.series;
            %                         paramMat = cell2mat(paramCell);
            %                         numSeries = max(paramMat);
            numSeries = max(params.series);
            if(numSeries>0);
                strength_results = PLM_count/numSeries;
                
                %strength attrition
                t = thresholdcrossings(params.series,0);
                y = (t(:,2)-t(:,1))'; %the number of PLM's per unbroken series
                x = 1:numel(y);
                if(numel(y)>1)
                    p = polyfit(x,y,1);
                    strength_attrition_results = p(1);
                else
                    strength_attrition_results = NaN;
                    
                end
            else
                strength_results = NaN;
                strength_attrition_results = NaN;
            end
            %plm attrition
            %                 hrs_slept = round(qParams.epoch(end)/120);%30/60/60 (30 second epochs divided by 3600 seconds to get hours
            stage_dur_hr = round(stage_dur_hour);
            hrs2epochs = 1*3600/30;  %3600 seconds/hour * 1 epoch/30 seconds
            if(stage_dur_hr>2)
                %                             PLM_epochs = qPredict.epoch(PLM_ind);
                
                halfway_epoch = (stage_dur_hr*hrs2epochs)/2;
                
                PLM_epochs = predictor_epochs(PLM_ind);
                plm_first_half = sum(PLM_epochs<halfway_epoch);
                plm_second_half = sum(PLM_epochs>halfway_epoch);
                if(plm_second_half ==0)
                    ratio_plm = NaN;
                else
                    ratio_plm = plm_first_half/plm_second_half;
                end
                lm_first_half =  sum(predictor_epochs<halfway_epoch);
                lm_second_half = sum(predictor_epochs>halfway_epoch);
                if(lm_second_half ==0)
                    ratio_lm = NaN;
                else
                    ratio_lm = lm_first_half/lm_second_half;
                end
                y = hist(PLM_epochs/120,1:stage_dur_hr);
                try
                    p = polyfit(1:stage_dur_hr,y,1);
                catch me
                    disp(me);
                    p = NaN;
                end
                plm_attrition_by_hour_results = p(1);

                LM_epochs = predictor_epochs;
                
                y = hist(LM_epochs/120,1:stage_dur_hr);
                try
                    p = polyfit(1:stage_dur_hr,y,1);
                catch me
                    disp(me);
                    p = NaN;
                end
                lm_attrition_by_hour_results = p(1);
                
                PLM_cycles = predictor_cycles(PLM_ind);
                num_cycles = max(PLM_cycles)-1;
                if(num_cycles>1)
                    y = hist(PLM_cycles(1:end-1),1:num_cycles);
                    try
                        p = polyfit(1:num_cycles,y,1);
                    catch me
                        disp(me);
                        p = NaN;
                    end
                    plm_attrition_by_cycle_results = p(1);
                else
                    plm_attrition_by_cycle_results = NaN;
                    
                end
                
                LM_cycles = predictor_cycles;
                num_cycles = max(LM_cycles)-1;
                if(num_cycles>1)
                    y = hist(LM_cycles(1:end-1),1:num_cycles);
                    try
                        p = polyfit(1:num_cycles,y,1);
                    catch me
                        disp(me);
                        p = NaN;
                    end
                    lm_attrition_by_cycle_results = p(1);
                else
                    lm_attrition_by_cycle_results = NaN;
                    
                end
            else
                plm_attrition_by_hour_results = NaN;
                plm_attrition_by_cycle_results = NaN;
                lm_attrition_by_hour_results = NaN;
                lm_attrition_by_cycle_results = NaN;
                ratio_lm = NaN;
                ratio_plm = NaN;
                fprintf(1,'Study less than 2 hours - studykey=%u\n',key);
            end
            plm_params_mat = cell2mat(plm_params);
            
            x = cell(size(plm_params_mat));
            [x{:}] = plm_params_mat.HR_slope;
            HR_slope = cell2mat(x);
            x = cell(size(plm_params_mat));
            [x{:}] = plm_params_mat.HR_delta;
            HR_delta = cell2mat(x);
            
            %periodicity
            periodicity_results = sum(params.meet_ferri_inter_lm_duration_criteria)/(LM_count-1);
            REMmetrics.PLMI = PLMI_results;
            REMmetrics.lmcount = LM_count;
            REMmetrics.periodicity = periodicity_results;
            REMmetrics.strength =strength_results;
            REMmetrics.attrition_plm_by_hour = plm_attrition_by_hour_results;
            REMmetrics.attrition_plm_by_cycle = plm_attrition_by_cycle_results;
            REMmetrics.attrition_lm_by_hour = lm_attrition_by_hour_results;
            REMmetrics.attrition_lm_by_cycle = lm_attrition_by_cycle_results;
            
            REMmetrics.attrition_strength = strength_attrition_results;
            REMmetrics.hrs_evaluated = stage_dur_hour;
            REMmetrics.HR_delta = mean(HR_delta);
            REMmetrics.HR_slope = mean(HR_slope);
            
            REMmetrics.ratio_plm = ratio_plm;
            REMmetrics.ratio_lm = ratio_lm;
        end
    end
end

end