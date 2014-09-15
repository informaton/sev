%> @file detection_artifact_nasalpressure.m
%> @brief This function calculates [start stop] for artefact periods in the
%> nasal pressure channel. Thresholds are adjusted to exclude
%> "more-than-less" artefact periods. If >75% of the recording contains
%> noise, the full recording is assigned as noisy.
% =========================================================================
%> @param Signal data vector.  (nasal pressure signal)
%> @param params A structure for variable parameters passed in
%> with following fields [ = default value]
%> @li @c window_dur_min [= 2] % Moving window duration = 2 minutes
%> @li @c window_overlap [= 0.8]; % Overlap moving window (0.8 = 80% overlap)
%> @li @c recording_quality_threshold [= 0.75]; % If more than 75% of the recording is bad quality, exclude all
%> @li @c samplerate
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data  Same as input signal (srcSig)
%> @li @c .new_events A two column matrix of start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c .paramStruct Empty value returned (i.e. []).
%> @note Written by Henriette Koch, 2014.
%  Added to SEV 8/22/2014, Hyatt Moore IV
function detectStruct = detection_artifact_nasalpressure(srcSig,params,stageStruct)


% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.window_dur_min = 2; % Moving window duration in minutes
defaultParams.window_overlap = 0.8; % Overlap moving window (0.8 = 80% overlap)
defaultParams.recording_quality_threshold = 0.75; % If more than 75% of the recording is bad quality, exclude all
        
% return default parameters if no input arguments are provided.
if(nargin==0)
    detectStruct = defaultParams;
else
    
    if(nargin<2 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future            
            params = defaultParams;
            plist.saveXMLPlist(pfile,params);
        end
    end
    
    
    Fs = params.samplerate;
    
    sigmax = prctile(srcSig,99.9);  % "True max"
    sigmax2 = max(abs(srcSig));     % Out of bound max
    
    % Window definition
    % num_ep = 4;                 % Moving window duration [1 epoch = 30 sec.], 4 = 2 minutes
    % ep_size = 30*Fs;            % Epoch size in samples
    % ws = floor(Fs*num_ep*30);   % Window size
    % olap = 0.8;                 % Overlap moving window
    ws = params.window_dur_min*60*Fs;
    ws_half = floor(ws/2);
    olap = params.window_overlap;
    lbw = floor(olap*ws);       % Length between windows
    sigw = floor(size(srcSig,1)/lbw); % Number of windows
    
    % FFT settings
    freqrange = [1 Fs/2];
    % T_si = 1/Fs;               % Sampling time
    % t_si = (0:ws-1)*T_si;      % Time vector  %unused?
    nfft_si = 2^nextpow2(ws);  % NFFT
    f_si = (Fs/2*linspace(0,1,nfft_si/2+1))'; % Frequency vector
    
    
    [idx ~] = find(f_si >= freqrange(1) & f_si <= freqrange(end)); % define frequency range
    lidx = floor(size(idx,1)/2);
    s1=freqrange(1); s2=floor(lidx/8); % 1-6 Hz
    s3=floor(lidx/4); s4=lidx; % 12-Fs/2 (50 Hz) Hz
    
    pres_exclude_ini = nan(sigw-1,2);
    
    % Exclude using amplitude
    for e = 1:sigw-1
        st = (e-1)*lbw+1; % window start
        w = st:st+ws-1; % define window
        
        % Exclude using distribution of signal amplitude - detect out of bound
        % parts, hard coded threshold is optimized by trial and error.
        if prctile(srcSig(w)/sigmax,95) > 0.02 && prctile(srcSig(w)/sigmax,5) < -0.02
            
            % Exclude using PSD in combination with signal amplitude - detect white noise
            y = fft(srcSig(w),nfft_si);
            Pyy = y.*conj(y)/nfft_si;  % power
            
            % Calculate slope differences between frequencies 1-6 and 12-50 Hz (log due to high power in low frequencies)
            % "True" nasal pressure when low frequencies decrease logarithmic and high is constant.
            % "False" if low frequencies are constant.
            
            slope1 = polyfit(s1:s2,log(Pyy(idx(s1:s2))'),1);
            slope2 = polyfit(s3:s4,log(Pyy(idx(s3:s4))'),1);
            
            %         slo(e,:) = [slope1(1) slope2(1)];
            %         a(e) = prctile(abs(insig(w))/sigmax2,85);
            %         b(e) = abs(slope1(1)/slope2(1));
            
            % If slope is above threshold, the nasal pressure is noisy
            if abs(slope1(1)/slope2(1)) < 10 && prctile(abs(srcSig(w))/sigmax2,85) < 0.1
                pres_exclude_ini(e,:) = [st-ws_half st+ws_half-1]; % [start stop] for excluded sampels
            end
        else
            pres_exclude_ini(e,:) = [st-ws_half st+ws_half-1]; % [start stop] for excluded sampels, take out two epoch size before and after
        end
    end
    
    pres_exclude_ini(isnan(pres_exclude_ini(:,1)),:) = [];
    
    % OUTPUT
    if ~isempty(pres_exclude_ini)
        % Clean up excluded periods, overlapped excluded "events" are merged
        artefact = eventoverlap(pres_exclude_ini);
        
        % Adjust first and last exclude sample if <1 og >size signal
        if artefact(1,1) <= 0
            artefact(1,1) = 1;
        end
        if artefact(end,2) > size(srcSig,1)
            artefact(1,1) = size(srcSig,1);
        end
        
        % If more than 75% of the recording is bad quality, exclude all
        if sum(artefact(:,2)-artefact(:,1))/size(srcSig,1) > params.recording_quality_threshold
            artefact = [1 size(srcSig,1)];
        end
        
    else
        artefact = [NaN NaN]; % if no nasal pressure artefacts
        
    end
    
    detectStruct.new_events = artefact;
    detectStruct.new_data = srcSig;
    detectStruct.paramStruct = [];
end
end



function [eventout] = eventoverlap(eventin)
% This function merges overlapping events.
% Written by Henriette Koch, 2014.
%
% INPUT
% eventin: input event vector [start stop], two column matrix.
%
% OUTPUT
% eventout: output event vector where events are merged [start stop], two
% column matrix.
% =========================================================================


% Overlapped events are merged
A = [[eventin(:,1);NaN] [NaN;eventin(:,2)]]; % prepare for subtracting
A(A(:,2)-A(:,1)>=0,:)=[]; % delete overlapping start/stop
hstart = A(1:end-1,1); hend = A(2:end,2); % define new start/stop

eventout = [hstart hend]; % OUTPUT: merged event vector

end