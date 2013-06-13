function output =  merge_events(evts,fs,distanceApart_sec,additional_buffer_sec)
% output =  merge_events(evts,fs,distanceApart_sec,additional_buffer_sec)
%artifacts is a Nx2 matrix of start and stop sample times
%fs is the sampling rate in samples/second
%The function follows a few rules in making its output
%   a.  If consecutive artifacts are within (<=) 1 second from each other,
%they are first combined
%   b.  Otherwise, 0.5 seconds are added to the start and stop of each
%artifact (with the exception of the first and last artifact since it is
%easier that way than checking the boundary conditions of these cases

% Hyatt Moore IV (< June, 2013)
% June, 13, 2013 note: this should be put into the class_events or class_events_container
% class if it is not already there:
if(nargin<4)
    additional_buffer_sec = 0.5; %how much extra to tack on to each side
end;

if(nargin<3)
    distanceApart_sec = 5+2*additional_buffer_sec; %5 seconds apart + .5 from each that would have been added on
end;

[r c] = size(evts);
if(c~=2)
    output = evts;
else
    output = zeros(r,c);
    k_out = 1;
    output(k_out,:) = evts(k_out,:);
    for k=2:r
        if(evts(k,1)-output(k_out,2)<=fs*distanceApart_sec) %combine if 1.5 seconds apart
            output(k_out,2)=evts(k,2); %combine the two times
        else
            output(k_out,:) = output(k_out,:)+additional_buffer_sec*fs*[-1,1];
            k_out = k_out+1;
            output(k_out,:) = evts(k,:);
        end;
    end;

    output = output(1:k_out,:); %truncate to only get the portion that was filled
    output(1)=max(1,output(1)); %check the corner case where we removed too much time...
    
    %second pass, add the .5 seconds on to each part
%     output(2:end,1) = output(2:end,1)-floor(fs/2);
%     output(1:end-1,2) = output(1:end-1,2)+floor(fs/2);
end;