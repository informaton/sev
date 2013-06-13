function confusionVector = binaryclassifiers2confusion(true_classifications, predicted_classifications)
% function confusionVector = binaryclassifiers2confusion(true_classifications, predicted_classifications)
%   transforms binary classification vectors into a confusion vector of count values
%   confusionVector = [TPC,FNC,FPC,TNC];
%      values in the classification vectors are interepreted as follows:
%      values of 1 are treated as positives
%      values of 0 are treated as negatives
%
%

%  Hyatt Moore, IV
%   < June, 2013
%

%positive samples have a value of two, while negative diagnosis are zero; 
%this is done to help distinguish TP, FN, FP, and TN below when compared to
%the estimated diagnosis

%ground truth positive samples are assigned values of two, 
%ground truth negatives remain zero
%Now they can be simply added with the 1/0 (P/N) values of the predicted classifer
%to determine the contingency vector directly
result = true_classifications(:)*2 + predicted_classifications(:); 
TP = sum(result==3); %b11
FN = sum(result==2); %b10
FP = sum(result==1); %b01
TN = sum(result==0); %b00
confusionVector = [TP,FN,FP,TN];
