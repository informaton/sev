function epoch = sample2epoch(index,epoch_dur_sec,sampleRate)
% function epoch = sample2epoch(index,epoch_dur_sec,sampleRate)
%returns the epoch for the given sample index of a signal that uses an
%epoch size in seconds of epoch_dur_sec and that was sampled at a sample
%rate of sampleRate - works with vectors of values as well.
%[DEFAULT] = [VALUE]
%[epoch_dur_sec] = [30]
%[sampleRate] = [100]

% Hyatt Moore, IV (< June, 2013)
if(nargin<3)
    sampleRate = 100;
end
if(nargin<2)
    epoch_dur_sec = 30;
end;
epoch = ceil(index/(epoch_dur_sec*sampleRate));