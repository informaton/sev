function [chi_square,p_value,odds_ratios] = contingency2chi(contingency)
%returns the chisquare for matrix cont which is a matrix of flattened
%contingnecy tables, with each row representing a contingency table
%%
%Consider the following contingency Table where A and B are the outcomes
%and 1 and 2 are the treatments
%  A   B
%1[1   2]  sumOne = 1+2
%2[3   4]  sumTwo = 3+4
%sumA sumB Tot= sumA+sumB=sumOne+sumTwo

% Hyatt Moore, IV
% < June, 2013

%For me:
% 1 is Controls
% 2 is RLS
% A is absence of symptoms
% B is presence of symptoms
totals = sum(contingency,2); %sum the cols
sumOne = sum(contingency(:,1:2),2);
sumTwo = sum(contingency(:,3:4),2);
sumA = sum(contingency(:,[1,3]),2);
sumB = sum(contingency(:,[2,4]),2);
chi = contingency(:,1).*contingency(:,4)-contingency(:,2).*contingency(:,3);

%turn this into a percentage now
percentage_contingency = contingency./repmat(totals,1,size(contingency,2));

chi_square = totals./(sumOne.*sumTwo.*sumA.*sumB).*chi.^2;
p_value = 1-chi2cdf(chi_square,1);
odds_group1 = percentage_contingency(:,2)./percentage_contingency(:,1);
odds_group2 = percentage_contingency(:,4)./percentage_contingency(:,3);

odds_ratios = [odds_group1,odds_group2,odds_group2./odds_group1];
%the cont would be = [1 2 3 4]

