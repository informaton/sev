function edf_ready_data = double2edfReadyData(signal,HDR,k)
%hdr is the HDR information only for the signal passed
% 

% helper function for something, but it has been a while
% Hyatt Moore, IV
% < June, 2013
    edf_ready_data = int16((signal-HDR.physical_minimum(k))*(HDR.digital_maximum(k)-HDR.digital_minimum(k))/(HDR.physical_maximum(k)-HDR.physical_minimum(k))+HDR.digital_minimum(k));
end