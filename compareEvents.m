function [score, event_space,sumAandB,sumAorB] = compareEvents(matA,matB,varargin)
% [score, event_space,sumAandB,sumAorB] = compareEvents(matA,matB,varargin)
%A and B are (n and/or m)x2 matrices whose first column is the
%starting point of an event while the second column is the ending point of
%the event.  Score is the result of A&&B/(A||B).  
%variable arguments in may be the start and stop of what is desired to be
%compared all together which is helpful if only a subset of the data was
%analyzed by A and/or B
%event_space is the matrix of where events overlapped with one another
%the events of A or the rows, and the events of B's are the columns
%locations with a value of 1/true represent an overlap of the two events at
%that position.
%
% called by CLASS_events_container.compareEvents() function
%

% Hyatt Moore, IV (< June, 2013)
AandB = [];
AorB = [];


curA = 1;
curB = 1;

A.start = matA(:,1);
A.end = matA(:,2);
B.start = matB(:,1);
B.end = matB(:,2);

if(numel(varargin)==1)
    start_stop = varargin{1};
    if(iscell(start_stop))
        start_stop = cell2mat(start_stop);
    end;
    %required to start within the boundaries specified by start_stop
    Aind = (A.start>=start_stop(1)&A.start<=start_stop(2));
    A.start = A.start(Aind);
    A.end = A.end(Aind);
    Bind = (B.start>=start_stop(1)&B.start<=start_stop(2));
    B.start = B.start(Bind);
    B.end = B.end(Bind);
    
end;

nA = numel(A.start); %number of rows in each
nB = numel(B.start);
event_space = false(nA,nB);
    
if(~(nA&&nB)) %nothing in either matrix, so they are the same with no detections (all negative)
    score = 100;    
elseif(xor(nA,nB)) %one is empty and thus there is 0 overlap
    score = 0;
else
    while(curA<=nA && curB<=nB)
        
        if(A.end(curA) < B.start(curB)) %A is before B and does not overlap
            AorB(end+1,:) = [A.start(curA), A.end(curA)];
            AandB(end+1,:) = [0, 0]; %no match in this case
            curA = curA+1;
        elseif(A.start(curA)>B.end(curB)) %%A is after B and does not overlap
            AorB(end+1,:) = [B.start(curB), B.end(curB)];
            AandB(end+1,:) = [0, 0];
            curB = curB+1;
        else %there is overlap
            event_space(curA,curB)=true;
            if(A.start(curA) < B.start(curB)) %A starts before B does
                AorB(end+1,:)=[A.start(curA), 0];
                if(B.end(curB)==A.end(curA)) %case 1:
                    AandB(end+1,:) = [B.start(curB), B.end(curB)];
                    AorB(end,2)=A.end(curA);
                    curA=curA+1;
                    curB=curB+1;
                elseif(B.end(curB)<A.end(curA)) %case 2: B ends earlier than A
                    AandB(end+1,:) = [B.start(curB), B.end(curB)];
                    AorB(end,2)=B.end(curB);
                    A.start(curA) = B.end(curB)+1;
                    curB = curB+1;
                else %case 3: A ends earlier than B
                    AandB(end+1,:) = [B.start(curB) A.end(curA)];
                    B.start(curB) = A.end(curA)+1;
                    AorB(end,2)=A.end(curA);
                    curA = curA+1;
                end
            else %B starts before A does...
                AorB(end+1,:)=[B.start(curB), B.end(curB)];
                if(B.end(curB)==A.end(curA)) %case 1:
                    AandB(end+1,:) = [A.start(curA), A.end(curA)];
                    curA=curA+1;
                    curB=curB+1;
                elseif(B.end(curB)<A.end(curA)) %case 2: B ends earlier than A
                    AandB(end+1,:) = [A.start(curA) B.end(curB)];
                    A.start(curA) = B.end(curB)+1;
                    curB = curB+1;
                else %case 3: A ends earlier than B
                    AandB(end+1,:) = [A.start(curA), A.end(curA)];
                    B.start(curB) = A.end(curA)+1;
                    AorB(end,2)=A.end(curA);
                    curA = curA+1;
                end
            end
        end;
        
    end; %end while...
    
    %clean up the rest...
    for k = curA:nA
        AorB(end+1,:) = [A.start(k),A.end(k)];
        AandB(end+1,:) = [0, 0];
    end
    for k =curB:nB
        AorB(end+1,:) = [B.start(k),B.end(k)];
        AandB(end+1,:) = [0, 0];
    end
    
    %compute the score:
    diffAorB = diff(AorB');
    sumAorB = sum(diffAorB)+sum(diffAorB>0);  %+numel(..>0) in order to account for the difference between the call to diff and the answer (e.g. diff([5 10]') = 5, but we really have six numbers here from 5 to 10
    diffAandB = diff(AandB');
    sumAandB = sum(diffAandB)+sum(diffAandB>0);
    
    score = sumAandB/sumAorB;
end;

