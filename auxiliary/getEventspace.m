function [event_space,AandB,AorB,interaction_matrix,N_count] = getEventspace(matA,matB,comparisonRanges, default_avgA_duration)
%A and B are (n and/or m)x2 matrices whose first column is the
%starting point of an event while the second column is the ending point of
%the event.  Score is the result of A&&B/(A||B).  
%variable arguments in may be the start and stop of what is desired to be
%compared all together which is helpful if only a subset of the data was
%analyzed by A and/or B
%event_space is the matrix of where events overlapped with one another
%the events of A are the rows, and the events of B's are the columns
%locations with a value of 1/true represent an overlap of the two events at
%that position.
%
% written by Hyatt Moore IV
%
% updated August 6, 2012 - added N_count output and associated logic
% N_count is the number of negative events classified by matA, which is
% determined by subtracting the duration of positive classified events in
% matA from the duration found in the comparison range and dividing the
% result by number of events in matA (i.e. the number of rows).
%
% updated August 4, 2012: added screenEvents function call to handle the
% input comparison_ranges variable (i.e. varargin{1}
%
% updated May 3, 2013: added default_duration which is an optional input
% that can be used for bounding the event size (max and min together) and
% helps calculate N_count in cases where matA is empty and the average 
% duration cannot be determined.

N_count = 0;
if(nargin>=3 && ~isempty(comparisonRanges))
    matA = screen_events(matA, comparisonRanges);
    matB = screen_events(matB, comparisonRanges);
    comparison_dur = sum(comparisonRanges(:,2)-comparisonRanges(:,1));
    
%% this was the old way of handling comparison range - using a single case
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
else
    comparison_dur = max([matA(:,2);matB(:,2)])-min([matA(:,1);matB(:,1)]);
end;


AandB = [];
AorB = [];
event_space = zeros(size(matA,1),size(matB,1));

% if(isempty(matB))
%     event_space = zeros(size(matA,1),1);
% else
%     event_space = zeros(size(matA,1),size(matB,1));
% end

interaction_matrix = event_space;
values = [];

curA = 1;
curB = 1;

A.start = matA(:,1);
A.end = matA(:,2);
A.value = 1;
B.start = matB(:,1);
B.end = matB(:,2);
B.value = 2;


nA = numel(A.start); %number of rows in each
nB = numel(B.start);
event_space = false(nA,nB);

if(~(nA||nB)) %nothing in either matrix, so they are the same with no detections (all negative)
    %     score = 100;
    fprintf('%s failed. Empty input entries\n',mfilename('fullpath'));
    if(nargin>3 && ~isempty(default_avgA_duration))
        N_count = floor(comparison_dur/default_avgA_duration);
    end

elseif(xor(nA,nB)) %one is empty and thus there is 0 overlap
    %     score = 0;
    fprintf('%s failed\n',mfilename('fullpath'));
    if(nA==0)
        if(nargin>3 && ~isempty(default_avgA_duration))
            avgDur = default_avgA_duration;
        else
            matB_dur = matB(:,2)-matB(:,1)+1;
            avgDur = mean(matB_dur);
        end
        N_count = floor(comparison_dur/avgDur); %no positive results classified by ground truth here; all events are negative then by the ground truth
%         event_space = zeros(1,size(matB,1));
    else
        matA_dur = matA(:,2)-matA(:,1);
        avgAEvt = mean(matA_dur);
        N_count = floor((comparison_dur-sum(matA_dur))/avgAEvt);
%         event_space = zeros(size(matA,1),1);
    end
%     interaction_matrix = event_space;

else
    matA_dur = matA(:,2)-matA(:,1);

    if(nargin>3 && ~isempty(default_avgA_duration))
        avgAEvt = default_avgA_duration;
    else
        avgAEvt = mean(matA_dur);
    end
    N_count = floor((comparison_dur-sum(matA_dur))/avgAEvt);
    
%     matB_dur = matB(:,2)-matB(:,1)+1;
    while(curA<=nA && curB<=nB)
        
        % A is before B and does not overlap
        if(A.end(curA) < B.start(curB)) 
            AorB(end+1,:) = [A.start(curA), A.end(curA)];
            AandB(end+1,:) = [0, 0]; %no match in this case
            values(end+1,:) = A.value;
            curA = curA+1;
            
        % A is after B and does not overlap
        elseif(A.start(curA)>B.end(curB)) 
            AorB(end+1,:) = [B.start(curB), B.end(curB)];
            AandB(end+1,:) = [0, 0];
            values(end+1,:) = B.value;
            curB = curB+1;
            
        %%there is overlap
        else 
            event_space(curA,curB)=true;
            % A starts before B does
            if(A.start(curA) < B.start(curB)) 
                AorB(end+1,:) = [A.start(curA), 0];
                if(B.end(curB) == A.end(curA)) %case 1: A and B end at the same spot
                    AandB(end+1,:) = [B.start(curB), B.end(curB)];
                    AorB(end,2) = A.end(curA);
                    curA = curA+1;
                    curB = curB+1;
                elseif(B.end(curB)<A.end(curA)) %case 2: B ends earlier than A
                    AandB(end+1,:) = [B.start(curB), B.end(curB)];
                    AorB(end,2)=A.end(curA);
%                     A.start(curA) = B.end(curB)+1;
                    curB = curB+1;
                else %case 3: A ends earlier than B
                    AandB(end+1,:) = [B.start(curB) A.end(curA)];
%                     B.start(curB) = A.end(curA)+1;
                    AorB(end,2) = B.end(curB);
                    curA = curA+1;
                end
%                 values(end+1,:) = A.value;
            % B starts before A does
            else 
                AorB(end+1,:) = [B.start(curB), 0];
                if(B.end(curB) == A.end(curA)) %case 1:
                    AandB(end+1,:) = [A.start(curA), A.end(curA)];
                    AorB(end,2) = A.end(curA);
                    curA=curA+1;
                    curB=curB+1;

                elseif(B.end(curB)<A.end(curA)) %case 2: B ends earlier than A
                    AandB(end+1,:) = [A.start(curA) B.end(curB)];
                    AorB(end,2)= A.end(curA);
%                     A.start(curA) = B.end(curB)+1;
                    curB = curB+1;
%                     values(end+1,:) = A.value;

                else %case 3: A ends earlier than B
                    AandB(end+1,:) = [A.start(curA), A.end(curA)];
%                     B.start(curB) = A.end(curA)+1;
                    AorB(end,2) = B.end(curB);
                    curA = curA+1;
%                     values(end+1,:) = B.value;

                end
%                 values(end+1,:) = B.value;

            end
            values(end+1,:) = A.value+B.value;
        end;
        
    end; %end while...
    
    %clean up the rest...
    for k = curA:nA
        AorB(end+1,:) = [A.start(k),A.end(k)];
        AandB(end+1,:) = [0, 0];
        values(end+1,:) = A.value;
    end
    for k =curB:nB
        AorB(end+1,:) = [B.start(k),B.end(k)];
        AandB(end+1,:) = [0, 0];
        values(end+1,:) = B.value;
    end

    %determine the amount of time/samples covered by AorB - the plus one is
    %here because the start and stop values are inclusive
    %merge back together now...
    diffAorB = diff(AorB')'+1;
%     diffAorB(diffAorB>0)=diffAorB(diffAorB>0)+1;
    
    diffAandB = diff(AandB')'+1;
%     diffAandB(diffAandB>0)=diffAandB(diffAandB>0)+1;


    %however, because the +1 is added, we have to exclude the times when
    %there is a value of 1 in the diff's due to zeros being seen as
    %inclusive.
    
%     another approach is to do the diff, add one, and then set the indices that are zeros in AandB to 0 in the AandB matrix;
    %cohens kappa (?)
    %The score is the NxM matrix of overlap scores
    score = diffAandB./diffAorB;
    interaction_matrix = zeros(size(event_space));
    matches = event_space==1;
    interaction_matrix(matches) = score(values == A.value+B.value);
    
%     %compute the score:
%     diffAorB = diff(AorB');
%     sumAorB = sum(diffAorB)+sum(diffAorB>0);  %+numel(..>0) in order to account for the difference between the call to diff and the answer (e.g. diff([5 10]') = 5, but we really have six numbers here from 5 to 10
%     diffAandB = diff(AandB');
%     sumAandB = sum(diffAandB)+sum(diffAandB>0);
%     
%     score = sumAandB/sumAorB;

end;

%questions to consider

%1.  How do I handle a single predicted event that covers two/multiple
%actual events?
   %only evaluate the cases of detection where it passes a threshold.  
%2.  How do I handle an actual event that is spanned by two or more
%predicted events?
   %2a.  I could sum the row and merge the columns if/when the events pass a threshold.
   %2b. I could ignore it and treat each case separately as a detection or
   %not
   
% I will assume that actual events will not be so close together to make
% this a problem...