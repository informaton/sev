function [confusionMatrix,precision,recall,split_count,span_count] = eventspace2confusion(eventspace,N_count,split_vec,span_vec)
% function [confusionMatrix,precision,recall] = eventspace2confusionmatrix(eventspace)
%   transforms an NxM event space matrix (of binary cell values) into a 2x2
% confusion matrix containing count values
%    confusionMatrix = [TPC,FNC,FPC,TNC];
% N_count is the number of negative classifications made by the primary
% detector that is being compared against (i.e. represented by the rows)
%
% [rows, cols ] = size(eventspace);
%
% split_vec is a vector of size rows with elements containing the number of times it was split by the predicting classifier
% span_vec is a vector of size cols with elements containing the number of true events spanned by the predicting classifier
%
% split_index = 
% Precision = Total Hits/Number of Predicted Events
% = Total Hits/Number of Columns in Event Matrix
% 
% Similarly, Recall, defined as percentage of hits made in comparison to the total number of hits possible, can be calculated using formula (X.R).
% 
% Recall = Total Hits/Number of Gold Standard Events
% = Total Hits/Number of Rows in Event Matrix
%
% split index = 

% 
% TotE = #rows + #columns
% TPC = Sum of all hits in the event space matrix (Total Hits (max is number of rows))
% FPC = #columns - TPC
% FNC = #rows - TPC
% TNC* = TotE ? Sum of {TPC,FPC,FNC} 
% 
% Precision = TotE/#columns
% Recall = TotE/#rows
% 
% Written by Hyatt Moore IV
% updated August 6, 2012 - added N_count as input argument to agument
% eventspace which does not include information to derive the number of
% negatively classified events in the evaluated data set.

if(isempty(eventspace))
    TPC = 0;
    FPC = 0;
    TNC = 1;
    FNC = 0;
    col = 1;
    row = 1;
else
    [row,col] = size(eventspace);
    TPC = sum(eventspace(:));
    FPC = col - TPC;
    FNC = row - TPC;
    
    if(nargin>1 &&~isempty(N_count))
        TNC = max(N_count-FPC,0); %this is because the number of negative events scored by the true classifier (N_count) is equal to the TN+FP
    else
        totE = row+col-TPC;
        TNC = totE - TPC;
        %     TNC = row - FPC; %otherwise, assume equal number of positive/negative events, since we cannot have multiple classifications of positive results in our data set (i.e. they would be merged or discarded).
        % TNC = totE - sum([TPC,FPC,FNC]);
        
    end
end

confusionMatrix = [TPC,FNC,FPC,TNC];
% normalizeconfusionmatrix = confusionMatrix/totE;
precision = TPC/col;
recall = TPC/row;
if(~TPC || nargin<3)
    split_count = 0;
    span_count = 0;
%     split_index = 0;
%     span_index = 0;
else
    split_count = sum(split_vec);
    span_count = sum(span_vec);
%     split_index = sum(split_vec)/TPC;
%     span_index = sum(span_vec)/TPC;
end

