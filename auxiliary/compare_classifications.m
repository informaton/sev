function comparisonStruct = compare_classifications(mat_ground_truth,mat_predictor,mat_Artifact,comparison_ranges)
% comparisonStruct = compare_classifications()
%    returns struct with string descriptors for each field
%
%
% comparisonStruct = compare_classifications(mat_ground_truth,mat_predictor,mat_Artifact,comparison_ranges)
%comparison range is the range of values that comparisons are allowed over...

if(nargin<1)
    comparisonStruct = confusion2roc();
    comparisonStruct.split_count = 'Split count';
    comparisonStruct.span_count = 'Span count';
    comparisonStruct.confusion_matrix_count = 'Confusion matrix count';
else
    
    % [TPR,FPR,K_1_0,K_0_0, CohensKappa,PPV,NPV, accuracy,precision,recall,f_measure,confusion_matrix_count] = compare_classifications(mat_ground_truth,mat_predictor,mat_Artifact,comparison_ranges)
    % [TPR,FPR,K_1_0,K_0_0, CohensKappa,PPV,NPV, accuracy,precision,recall,f_measure,confusion_matrix_count] = compare_classifications(mat_ground_truth,mat_predictor,mat_Artifact,comparison_ranges)
    
    % Hyatt Moore, IV (< June, 2013)
    
    if(~issorted(mat_ground_truth(:,1)))
        [~,ind]=sort(mat_ground_truth(:,1));
        mat_ground_truth = mat_ground_truth(ind,:);
    end
    if(~issorted(mat_predictor(:,1)))
        [~,ind]=sort(mat_predictor(:,1));
        mat_predictor = mat_predictor(ind,:);
    end
    
    predictive_threshold = 0.05;
    samplerate = 100;
    max_evt_dur_sec = 5; %maximum event duration allowed
    min_evt_dur_sec = 0.5; %minimum event duration allowed
    avg_evt_dur_sec = 2.75;
    default_ground_truth_size = samplerate*avg_evt_dur_sec;
    if(nargin>=3 && ~isempty(mat_Artifact))
        if(~issorted(mat_Artifact(:,1)))
            [~,ind]=sort(mat_Artifact(:,1));
            mat_Artifact = mat_Artifact(ind,:);
        end
        sample_rate = 100;
        % any overlap within  +/- 1.5 seconds of an apneic event should be removed
        exclude_respiratory_distance_sec = 2.5;
        exclusion_type = 'custom';
        plus_minus_overlap_win = exclude_respiratory_distance_sec*sample_rate;  %remove any with overlap
        mat_ground_truth = exclude_artifact(mat_ground_truth,mat_Artifact,plus_minus_overlap_win,exclusion_type);
        mat_predictor = exclude_artifact(mat_predictor,mat_Artifact,plus_minus_overlap_win,exclusion_type);
    end
    
    if(nargin<4)
        comparison_ranges = [];
    end
    
    [~,~,~,interaction_matrix_ground_truth_vs_predictor,N_count] = getEventspace(mat_ground_truth,mat_predictor,comparison_ranges,default_ground_truth_size);
    %scored_event_space = scoreEventspace(interaction_matrix_ground_truth_vs_predictor,predictive_threshold);
    [scored_event_space, split_vec, span_vec] = scoreEventspace_with_bridges_and_splits(interaction_matrix_ground_truth_vs_predictor,predictive_threshold);
    [confusion_matrix_count,~,~,split_count,span_count] = eventspace2confusion(scored_event_space,N_count,split_vec,span_vec);
    %     [TPR,FPR,K_1_0,K_0_0, CohensKappa,PPV,NPV, accuracy,precision,recall,f_measure] = confusion2roc(confusion_matrix_count/sum(confusion_matrix_count));
    rocStruct = confusion2roc(confusion_matrix_count/sum(confusion_matrix_count));
    comparisonStruct = rocStruct;
    comparisonStruct.split_count = split_count;
    comparisonStruct.span_count = span_count;
    comparisonStruct.confusion_matrix_count = confusion_matrix_count;
end
end