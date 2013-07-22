function [cleanedEvents, clean_indices] = removeOverlappingRespiratoryEvents(matEvents,matArtifact,exclusionArea)
%function [cleanedEvents, clean_indices] = removeOverlappingRespiratoryEvents(matEvents,matArtifact,exclusionArea)
%matEvents and matArtifact are two column matrices of events.  They are sorted, and
%then compared for overlap at 'predictive_threshold' level.  If the
%threshold is exceeded, then events in matA (rows) are removed
% if predictive_threshold is excluded, it defaults to 0.05
%cleanedEvents is matA after excluding rows that overlap with matB by more
%than predictive_threshold
%clean_indices are the indices held, which did not have overlapping
%respiratory events
%exclusion_area - optional string, which can be 
%   'both' remove around offset and onset [default]
%   'offset' remove around offset
%   'onset' remove around onset
%   'beforeoffset' remove before offset
%   'beforeonset' remove before onset to onset
%   'afteroffset' remove offset to after offset
%   'afteronset' remove from onset to exclude_win after onset
%

% Hyatt Moore, IV (< June, 2013)
% 7/21/2013: clean_indices now returns a vector of the number of rows in
%            matEvents when no respiratory events are found;
if(isempty(matArtifact)||isempty(matEvents))
    cleanedEvents = matEvents;
    clean_indices = 1:size(matEvents,1);
else
    if(~issorted(matArtifact(:,1)))
        [~,ind]=sort(matArtifact(:,1));
        matArtifact = matArtifact(ind,:);
    end
    if(~issorted(matEvents(:,1)))
        [~,ind]=sort(matEvents(:,1));
        matEvents = matEvents(ind,:);
    end
    
    if(nargin<3)
        exclusionArea = 'both';
    end
    sample_rate = 100;
    % any overlap within  +/- 1.5 seconds of an apneic event should be removed
    % exclude_respiratory_distance_sec = 0.0;
    exclude_respiratory_distance_sec = 2.5;
    exclude_respiratory_distance_sec = 10;
    
    %aasm criteria
    exclude_respiratory_distance_sec = 0.5;
    
    
    
    plus_minus_overlap_win = exclude_respiratory_distance_sec*sample_rate;  %remove any with overlap
    [cleanedEvents,clean_indices] = exclude_artifact(matEvents,matArtifact,plus_minus_overlap_win,exclusionArea);
end
