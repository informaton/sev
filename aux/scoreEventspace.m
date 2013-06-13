function scored_event_space = scoreEventspace(interaction_matrix,threshold)
%applies a greedy algorithm to the interaction_matrix using the given
%threshold to determine the scored_event_space
%The greedy algorithm is described here:
% For an interaction matrix of N rows and M columns, repeat the following steps for each row beginning at the first row.
% 1.  Calculate the sum of the row as Rsum[i] where i corresponds to the ith row.
% 2.  Let R[i]C[events] represent the columns in the ith row that have an interaction score greater than 0.  
% 2.  Let R[i]C[max] represent the element in R[i]C[events] that contains the largest interaction score.
% 3.  Set all values in R[i] to zero.
% 4.  If Rsum[i] is greater than the threshold T
% a. Set all columns indexed by R[i]C[events] to zero.  
% b. Set the value of/at location R[i]C[max] to (RSum[i]-delete) a hit

% author Hyatt Moore IV 10/24/11
% Stanford University, Stanford CA
% Created: sometime in early 2012 most likely

scored_event_space = interaction_matrix*0;

for row_ind=1:size(interaction_matrix,1)
    Rsum = sum(interaction_matrix(row_ind,:));
    [~, Cmax_ind] = max(interaction_matrix(row_ind,:));
    if(Rsum>=threshold)
        scored_event_space(row_ind,Cmax_ind) = 1;
        interaction_matrix(:,interaction_matrix(row_ind,:)>0)=0; %zero out all other columns;
    end
end


% Rsum = sum(interaction_matrix,2);  %sum each row
% [Cmax, Cmax_ind] =max(interaction_matrix,[],2); %find the maximum values in each row and store their position


% AandB = [];
% AorB = [];
% 
% values = [];
% 
% curA = 1;
% curB = 1;
% 
% A.start = matA(:,1);
% A.end = matA(:,2);
% A.value = 1;
% B.start = matB(:,1);
% B.end = matB(:,2);
% B.value = 2;
% 
% if(numel(varargin)==1)
%     start_stop = varargin{1};
%     if(iscell(start_stop))
%         start_stop = cell2mat(start_stop);
%     end;
%     %required to start within the boundaries specified by start_stop
%     Aind = (A.start>=start_stop(1)&A.start<=start_stop(2));
%     A.start = A.start(Aind);
%     A.end = A.end(Aind);
%     Bind = (B.start>=start_stop(1)&B.start<=start_stop(2));
%     B.start = B.start(Bind);
%     B.end = B.end(Bind);
%     
% end;
% 
% nA = numel(A.start); %number of rows in each
% nB = numel(B.start);
% event_space = false(nA,nB);
%     
% if(~(nA&&nB)) %nothing in either matrix, so they are the same with no detections (all negative)
%     score = 100;    
% elseif(xor(nA,nB)) %one is empty and thus there is 0 overlap
%     score = 0;
% else
%     while(curA<=nA && curB<=nB)
%         
%         % A is before B and does not overlap
%         if(A.end(curA) < B.start(curB)) 
%             AorB(end+1,:) = [A.start(curA), A.end(curA)];
%             AandB(end+1,:) = [0, 0]; %no match in this case
%             values(end+1,:) = A.value;
%             curA = curA+1;
%             
%         % A is after B and does not overlap
%         elseif(A.start(curA)>B.end(curB)) 
%             AorB(end+1,:) = [B.start(curB), B.end(curB)];
%             AandB(end+1,:) = [0, 0];
%             values(end+1,:) = B.value;
%             curB = curB+1;
%             
%         %%there is overlap
%         else 
%             event_space(curA,curB)=true;
%             % A starts before B does
%             if(A.start(curA) < B.start(curB)) 
%                 AorB(end+1,:) = [A.start(curA), 0];
%                 if(B.end(curB) == A.end(curA)) %case 1: A and B end at the same spot
%                     AandB(end+1,:) = [B.start(curB), B.end(curB)];
%                     AorB(end,2) = A.end(curA);
%                     curA = curA+1;
%                     curB = curB+1;
%                 elseif(B.end(curB)<A.end(curA)) %case 2: B ends earlier than A
%                     AandB(end+1,:) = [B.start(curB), B.end(curB)];
%                     AorB(end,2)=A.end(curA);
% %                     A.start(curA) = B.end(curB)+1;
%                     curB = curB+1;
%                 else %case 3: A ends earlier than B
%                     AandB(end+1,:) = [B.start(curB) A.end(curA)];
% %                     B.start(curB) = A.end(curA)+1;
%                     AorB(end,2) = B.end(curB);
%                     curA = curA+1;
%                 end
% %                 values(end+1,:) = A.value;
%             % B starts before A does
%             else 
%                 AorB(end+1,:) = [B.start(curB), 0];
%                 if(B.end(curB) == A.end(curA)) %case 1:
%                     AandB(end+1,:) = [A.start(curA), A.end(curA)];
%                     AorB(end,2) = A.end(curA);
%                     curA=curA+1;
%                     curB=curB+1;
% 
%                 elseif(B.end(curB)<A.end(curA)) %case 2: B ends earlier than A
%                     AandB(end+1,:) = [A.start(curA) B.end(curB)];
%                     AorB(end,2)= A.end(curA);
% %                     A.start(curA) = B.end(curB)+1;
%                     curB = curB+1;
% %                     values(end+1,:) = A.value;
% 
%                 else %case 3: A ends earlier than B
%                     AandB(end+1,:) = [A.start(curA), A.end(curA)];
% %                     B.start(curB) = A.end(curA)+1;
%                     AorB(end,2) = B.end(curB);
%                     curA = curA+1;
% %                     values(end+1,:) = B.value;
% 
%                 end
% %                 values(end+1,:) = B.value;
% 
%             end
%             values(end+1,:) = A.value+B.value;
%         end;
%         
%     end; %end while...
%     
%     %clean up the rest...
%     for k = curA:nA
%         AorB(end+1,:) = [A.start(k),A.end(k)];
%         AandB(end+1,:) = [0, 0];
%         values(end+1,:) = A.value;
%     end
%     for k =curB:nB
%         AorB(end+1,:) = [B.start(k),B.end(k)];
%         AandB(end+1,:) = [0, 0];
%         values(end+1,:) = B.value;
%     end
%     
%     %merge back together now...
%     diffAorB = diff(AorB')'+1;
% %     diffAorB(diffAorB>0)=diffAorB(diffAorB>0)+1;
%     
%     diffAandB = diff(AandB')'+1;
% %     diffAandB(diffAandB>0)=diffAandB(diffAandB>0)+1;
% 
%     score = diffAandB./diffAorB;
%     scored_event_space = zeros(size(event_space));
%     matches = event_space==1;
%     scored_event_space(matches) = score(values == A.value+B.value);
% 
% 
%     
% %     %compute the score:
% %     diffAorB = diff(AorB');
% %     sumAorB = sum(diffAorB)+sum(diffAorB>0);  %+numel(..>0) in order to account for the difference between the call to diff and the answer (e.g. diff([5 10]') = 5, but we really have six numbers here from 5 to 10
% %     diffAandB = diff(AandB');
% %     sumAandB = sum(diffAandB)+sum(diffAandB>0);
% %     
% %     score = sumAandB/sumAorB;
% end;
% 
% %questions to consider
% 
% %1.  How do I handle a single predicted event that covers two/multiple
% %actual events?
%    %only evaluate the cases of detection where it passes a threshold.  
% %2.  How do I handle an actual event that is spanned by two or more
% %predicted events?
%    %2a.  I could sum the row and merge the columns if/when the events pass a threshold.
%    %2b. I could ignore it and treat each case separately as a detection or
%    %not
%    
% % I will assume that actual events will not be so close together to make
% % this a problem