function artifacts = processArtifacts(art,fs)
% artifacts = processArtifacts(art,fs)
%takes art and passes it to processArtifactsNx2 (art can be a vector)

% Hyatt Moore IV (< June, 2013)
%   likely not used any longer judging by the fs variable
[r,c] = size(art);

if(r==2||c==2)
    if(r==2)
        crossings=art';
    else
        crossings = art; %otherwise assume you are dealing with a 2D matrix
    end;
%     x_output = zeros(1,handles.user.duration_samples);
else
    crossings = thresholdcrossings(art,0);
%     x_output = zeros(1,length(art));
end;


artifacts = crossings;  

%use merge_events now instead of this...
%processArtifactsNx2(crossings,fs);