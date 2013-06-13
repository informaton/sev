function varargout = exclude_artifact(mat_original,mat_Artifact,exclude_win,exclusionArea)
%exclude_win is the +/- sample window to remove overlapping artifact data from in the mat_manual    
%mat_original is a Nx2 matrix of start, stop samples per row.  mat_Artifact
%is similar with rows representing the occurence of artifactual data that
%will be checked for overlap with the included window of +/- exclude_win
%size.
%exclusion_area - optional string, which can be 
%   'both' remove around offset and onset [default]
%   'offset' remove around offset
%   'onset' remove around onset
%   'beforeoffset' remove before offset
%   'beforeonset' remove before onset to onset
%   'afteroffset' remove offset to after offset
%   'afteronset' remove from onset to exclude_win after onset

    if(nargin<3)
        exclude_win = 250;
    end
    
    if(nargin<3)
        exclusionArea = 'both';
    end
    switch(lower(exclusionArea))
        case 'both'
            mat_Artifact = [mat_Artifact(:,1)-exclude_win, mat_Artifact(:,2)+exclude_win];
        case 'onset'
            mat_Artifact = [mat_Artifact(:,1)-10.0*100, mat_Artifact(:,1)+1.0*100];
        case 'afteronset'
            mat_Artifact = [mat_Artifact(:,1), mat_Artifact(:,1)+exclude_win];
        case 'beforeonset'
            mat_Artifact = [mat_Artifact(:,1)-exclude_win, mat_Artifact(:,1)];
        case 'offset'
            mat_Artifact = [mat_Artifact(:,2)-exclude_win, mat_Artifact(:,2)+exclude_win];
        case 'beforeoffset'
            mat_Artifact = [mat_Artifact(:,2)-exclude_win, mat_Artifact(:,2)];
        case 'afteroffset'
            mat_Artifact = [mat_Artifact(:,2)-2.0*100, mat_Artifact(:,2)+7.5*100];
        case 'custom'
            mat_OnsetArtifact = [mat_Artifact(:,1)-5.0*100,mat_Artifact(:,1)+0.5*100];
            mat_OffsetArtifact = [mat_Artifact(:,2)-0.5*100,mat_Artifact(:,2)+5*100];
%             mat_OnsetArtifact = [mat_Artifact(:,1)-6.0*100,mat_Artifact(:,1)+1.0*100];
%             mat_OffsetArtifact = [mat_Artifact(:,2)-1.0*100,mat_Artifact(:,2)+4.0*100];
            
    end
    
    %check for artifact overlap
    artifact_threshold = 0.00001;  %~any overlap
    hold_ind = [];
    if(~isempty(mat_original))
        if(strcmpi(exclusionArea,'custom'))
            if(~isempty(mat_OnsetArtifact) && ~isempty(mat_OffsetArtifact))                
                [~,~,~,interaction_matrix_predictor_vs_artifact] = getEventspace(mat_original,mat_OnsetArtifact);
                hold_ind = sum(interaction_matrix_predictor_vs_artifact,2)<artifact_threshold;
                [~,~,~,interaction_matrix_predictor_vs_artifact] = getEventspace(mat_original,mat_OffsetArtifact);
                hold_ind = hold_ind&sum(interaction_matrix_predictor_vs_artifact,2)<artifact_threshold;
                mat_original = mat_original(hold_ind,:);
            end
        elseif(~isempty(mat_Artifact))                
            [~,~,~,interaction_matrix_predictor_vs_artifact] = getEventspace(mat_original,mat_Artifact);
            hold_ind = sum(interaction_matrix_predictor_vs_artifact,2)<artifact_threshold;
            mat_original = mat_original(hold_ind,:);
        end

    end
    if(nargout>0)
        varargout{1} = mat_original;
    end
    if(nargout>1)
        varargout{2} = hold_ind;
    end
end
