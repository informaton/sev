function output =  processArtifactsNx2(art,fs,distanceApart_sec)
% output =  processArtifactsNx2(art,fs,distanceApart_sec)
%
%artifacts is a Nx2 matrix of start and stop sample times
%fs is the sampling rate in samples/second
%The function follows a few rules in making its output
%   a.  If consecutive artifacts are within (<=) 1 second from each other,
%they are first combined
%   b.  Otherwise, 0.5 seconds are added to the start and stop of each
%artifact (with the exception of the first and last artifact since it is
%easier that way than checking the boundary conditions of these cases

% Hyatt Moore IV (< June, 2013): may be in one of the event classes now
if(nargin<3)
    distanceApart_sec = 6; %5 seconds apart + .5 from each that would have been added on
end;
[r c] = size(art);
if(c~=2)
    output = art;
else
    output = zeros(r,c);
    k_out = 1;
    output(k_out,:) = art(k_out,:);
    for k=2:r-2
        if(art(k,1)-output(k_out,2)<=fs*distanceApart_sec) %combine if 1.5 seconds apart
            output(k_out,2)=art(k,2); %combine the two times
        else
            k_out = k_out+1;
            output(k_out,:) = art(k,:);
        end;
    end;

    output = output(1:k_out,:); %truncate to only get the portion that was filled

    %second pass, add the .5 seconds on to each part
    output(2:end,1) = output(2:end,1)-floor(fs/2);
    output(1:end-1,2) = output(1:end-1,2)+floor(fs/2);
end;