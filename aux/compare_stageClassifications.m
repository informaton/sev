function confusionVector = compare_stageClassifications(stage_ground_truth,stage_predictor,groupings,exclusion_stages)
%function [percentCorrect,numCorrect,numPossible] = compare_stageClassifications(stage_ground_truth,stage_predictor,groupings,exclusion_stages)
%groupings is a cell of the values to consider in the comparison, and how
%they should be evaluated by the detector
%groupings = {[1,2,3,4],[0,5]} is interested in nrem vs rem/wake groupings
%groupings = {1,2,3,4,5,0} is interested in each stage
% groupings = {5} is interested only in REM
%stages found that are not in either grouping, are removed from comparison
%exclusion_stages = vector of stages that should not be compared (e.g. 7)
%
% Author: Hyatt Moore IV
% Date: 8/27/12
%  Edited 8/30/12 - changed to output confusionVector approach
if(nargin==0)
    curDir = '/Users/hyatt4/Google Drive/gsev';
    disp('debug/demo mode');
    groupings = {[1,2,3,4],[0,5]};
    exclusion_stages = 7;
    loadFile = '/Users/hyatt4/Google Drive/gsev/staging_ocular.staging_ocularCorrel.0.txt';
    cd('/Users/hyatt4/Google Drive/gsev/');
    cd(curDir);
    
    evtStruct = CLASS_events_container.evtTxt2evtStruct(loadFile);
    
    stage_ground_truth = evtStruct.Stage;
    stage_predictor = evtStruct.stages;
    
else

    if(ischar(stage_ground_truth))
        stage_ground_truth = loadSTA(stage_ground_truth);
    end
    if(ischar(stage_predictor))
        stage_predictor = loadSTA(stage_predictor);
    end
end
% numGroups = numel(groupings);
    
%remove unwanted staged epochs as applicable (e.g. stage 7)
if(nargin>3 && ~isempty(exclusion_stages))
    exclusion_indices = false(size(stage_ground_truth));
    for e=1:numel(exclusion_stages)
        exclusion_indices = stage_ground_truth==exclusion_stages(e)|exclusion_indices;
    end
    stage_ground_truth(exclusion_indices)=[];
    stage_predictor(exclusion_indices)=[];
end

% numStages = numel(stage_ground_truth);
% numCorrect = 0;

% for g=1:numGroups
% group = groupings{g};
ground_truth_inclusion_indices = false(size(stage_ground_truth));
predictor_inclusion_indices = false(size(stage_predictor));

group = groupings{1};
for s=1:numel(group)
    stage = group(s);
    ground_truth_inclusion_indices = ground_truth_inclusion_indices|(stage_ground_truth==stage);
    predictor_inclusion_indices = predictor_inclusion_indices|(stage_predictor==stage);
end

true_classifications = ground_truth_inclusion_indices;
predicted_classifications = predictor_inclusion_indices;
confusionVector = binaryclassifiers2confusion(true_classifications, predicted_classifications);

% numCorrect = sum(ground_truth_inclusion_indices&predictor_inclusion_indices)+numCorrect;
% end

% percentCorrect = numCorrect/numStages*100;
% numPossible = numStages;


end

function stages = loadSTA(stages_filename)
    stages = load(stages_filename,'-ASCII'); %for ASCII file type loading
    stages = stages(:,2); %grab the sleep stages
end
