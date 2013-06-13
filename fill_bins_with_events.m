function filled_events = fill_bins_with_events(events, num_samples)
%this function breaks a timeline into num_samples chunks, and fills the
%entire chunck with 1's if it contains at least one event that is not 0
%events is a two column matrix of start and stop indices (columns 1 and 2)
%for the events

% written by Hyatt Moore IV (< June, 2013)
% Note: this is likely in one of the classes now...

first_events = [floor(events(:,1)/num_samples)*num_samples+1,ceil(events(:,2)/num_samples)*num_samples];
filled_events = zeros(size(first_events));

%clean up any overlapping portions...
% 10  40 -> 1 200
% 60 100 -> 1 200
%202 205 -> 201 400

%this then gets converted to an output of 
%1 200
%201 400

num_events = size(first_events,1);

cur_event = 1;
filled_events(cur_event,:) = first_events(cur_event,:);

for k = 2:num_events
    
    if(filled_events(cur_event,1)==first_events(k,1))
        if(filled_events(cur_event,2)~=first_events(k,2))
            filled_events(cur_event,2) = max(filled_events(cur_event,2),first_events(k,2));
            %else skip this one and move onto the next event since this is
            %a duplicate
        end
    else
        if(first_events(k,2)>filled_events(cur_event,2) && first_events(k,1)<filled_events(cur_event,2))
            filled_events(cur_event,2) = first_events(k,2);
        elseif(filled_events(cur_event,2)~=first_events(k,2))
            cur_event = cur_event+1;
            filled_events(cur_event,:) = first_events(k,:);
        end
    end
end

%just grab the ones we need - that were not duplicated..
filled_events = filled_events(1:cur_event,:);
