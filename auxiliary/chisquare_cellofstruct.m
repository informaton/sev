function [chisquare, p_value] = chisquare_cellofstruct(cellofstruct,field1, field2)
%function [chisquare, p_value] = chisquare_cellofstruct(cellofstruct,field1, field2)
% calculates a chisquare and associated p value between the input structures sub fields .(field1) or
% .(field1).(field2) for the different cell elements of the input
% cellofstruct

% Hyatt Moore, IV (< June, 2013)


%need to convert the cell of structs to a cell of doubles which can then be
%flattened and passed to anova1
if(~iscell(cellofstruct) || nargin<2 || isempty(field1))
    chisquare = nan;
    p_value = nan;
    fprintf(1,'Failed on chisquare_cellofstruct.m\n');
else
    contingency_table = zeros(numel(cellofstruct),2);
    if(nargin<3 || isempty(field2))
    
        field2= {'n_above','n_below'};
    end
    
    for c=1:numel(cellofstruct)
        contingency_table(c,:) = [cellofstruct{c}.(field1).(field2{1})(:),cellofstruct{c}.(field1).(field2{2})(:)];
    end
    
% Observed data
n_observed = contingency_table(:,1);
N_observed = contingency_table(:,2)+n_observed; %want to have proportions


pooled_estimate = sum(n_observed)/sum(N_observed);
n_expected = N_observed*pooled_estimate;

% Chi-square test, by hand
observed = [n_observed(:)';N_observed(:)'-n_observed(:)'];
expected = [n_expected(:)';N_observed(:)'-n_expected(:)'];

chisquare = sum((observed(:)-expected(:)).^2 ./ expected(:));
p_value = 1 - chi2cdf(chisquare,1);

               
end

% struct2cell(cell2mat(cellofstruct))

