function save_fft()
%function save_fft()
%calculate the FFTs of signal_x with sampling rate of FS,
%over a Ts second segments done ever interval seconds
%calculations are done using the fft with a hanning window and zero padding
%as necessary...
%x_bins is a vector containing the center points around which the histogram
%was made across
%nfft is the fft size that was used in calculating the PSD...

%Hyatt Moore IV
%June 13, 2013: This code was likely written in early 2010 when a postdoc
%was very interested in the fft's.  
% This is legacy code now, but I keep it here as a reminder of how my
% coding style has changed over the years (for the better, I hope!).

global CHANNELS_CONTAINER;
global CHANNEL_INDICES;
global STATE;
global DEFAULTS;
global PSD;
global STAGES;
global WORKSPACE;
global BATCH_PROCESS;

PRIMARY = CHANNELS_CONTAINER.cell_of_channels{CHANNEL_INDICES.PRIMARY};


if(~STATE.batch_process_running)
    h = waitbar(0,'Calculating FFT');
end;
% rows = floor(length(signal_x)/Fs/Ts) %- the old way of doing things back
% to back...
num_signal_window_sec = DEFAULTS.study_duration_in_seconds;
rows = floor((num_signal_window_sec-PSD.FFT_window_sec)/PSD.interval)+1;

% Use next highest power of 2 greater than or equal to length(x) to calculate FFT.
% nfft= 2^(nextpow2(Ts*Fs)); 

%use the same spacing as our window
nfft = PSD.FFT_window_sec*DEFAULTS.fs;

% Calculate the numberof unique points
NumUniquePts = ceil((nfft+1)/2);

% This is an evenly spaced frequency vector with NumUniquePts points. 
f = (0:NumUniquePts-1)*DEFAULTS.fs/nfft;

cols = NumUniquePts;
psd = zeros(rows,cols); %for Ts = 2 seconds and Fs = 100samples/sec, this breaks the signal into PSDs of 2sec chunks which are stored per row with bins [0.5 1-50] 


for r = 1:rows
    % Take fft, padding with zeros so that length(fftx) is equal to nfft
%     x = signal_x((r-1)*Ts*Fs+1:r*Ts*Fs);
    start = (r-1)*PSD.interval*DEFAULTS.fs+1;
    x = PRIMARY.raw_data(start:start+PSD.FFT_window_sec*DEFAULTS.fs-1);
  
    fftx = fft(x,nfft);

    % FFT is symmetric, throw away second half
    fftx = fftx(1:NumUniquePts);


    mx = abs(fftx/length(x));
    
    % Since we dropped half the FFT, we multiply mx by 2 to keep the same energy.
    % The DC component and Nyquist component, if it exists, are unique and should not be multiplied by 2.
    if rem(nfft, 2) % odd nfft excludes Nyquist point
        mx(2:end) = mx(2:end)*2;
    else
        mx(2:end -1) = mx(2:end -1)*2;
    end

    psd(r,:) = mx;
    
    if(~STATE.batch_process_running)
        if(mod(r,101)==0 && ishandle(h))
            waitbar(r/rows,h);
        end;
    end;

end;

if(~STATE.batch_process_running)
    if(ishandle(h))
        delete(h);
    end;
end;

filename_out = WORKSPACE.cur_filename;
if(STATE.batch_process_running)
    filename_out = [filename_out(1:end-3) BATCH_PROCESS.output_files.fft_filename];
else
    filename_out = [filename_out(1:end-3) 'fft.txt'];
end

if(~STATE.batch_process_running)
    h = waitbar(0,sprintf('Saving FFTs to %s',filename_out));
end;

y = psd;
rows = size(y,1);

% fft_art_indices = reshape(handles.user.final_art_density_line,PSD.FFT_window_sec*DEFAULTS.fs,[]);  %each column is an FFT epoch worth of samples from the artifact line
E = floor(0:PSD.interval/DEFAULTS.standard_epoch_sec:(DEFAULTS.study_duration_in_seconds-PSD.FFT_window_sec)/DEFAULTS.standard_epoch_sec)+1;
S = STAGES.line(E)';

%a bit backwards, but I'm short on time right now - ideally, I would like
%to not have to stretch out the data like this
artifact_line = zeros(1,DEFAULTS.study_duration_in_samples);

event_index = 1
for k=1:size(PRIMARY.event_object_cell{event_index}.start_stop_matrix,1)
    artifact_line(PRIMARY.event_object_cell{event_index}.start_stop_matrix(k,1):PRIMARY.event_object_cell{event_index}.start_stop_matrix(k,2))=1;    
end;

if(PSD.FFT_window_sec==PSD.interval)
    fft_art_indices = reshape(artifact_line,PSD.FFT_window_sec*DEFAULTS.fs,[]);  %each column is an FFT epoch worth of samples from the artifact line
    fft_art_indices = (sum(fft_art_indices)~=0)';
else
    fft_art_indices = zeros(rows,1);
    for k=1:rows
        start = (k-1)*PSD.interval*DEFAULTS.fs+1;
        fft_art_indices(k) = sum(artifact_line(start:start+PSD.FFT_window_sec*DEFAULTS.fs-1));
    end;
end;
fout = fopen(fullfile(WORKSPACE.cur_pathname,DEFAULTS.output_pathname,filename_out),'w');
analysis_CHANNEL_number = PRIMARY.EDF_index;
analysis_CHANNEL_label = PRIMARY.EDF_label;

fprintf(fout,['#FFTs with the following parameters:\r\n'...
    ,'#\tCHANNEL:\t%s (%i)\r\n'...
    ,'#\twindow length (seconds):\t%0.1f\r\n'...
    ,'#\tFFT length (samples):\t%i\r\n'...
    ,'#\tFFT interval (taken every _ seconds):\t%0.1f\r\n'...
    ,'%s\tA\tS\tE\r\n'...
    ,'#Note: The following is the energy conserved magnitude of one side of the symmetrical spectrum (i.e. spectrum was cut in half, absolute value was taken, and the result was multplied by 2)\r\n']...
    ,analysis_CHANNEL_label,analysis_CHANNEL_number,PSD.FFT_window_sec,nfft,...
    PSD.interval,num2str(f,'\t%0.1f'));
fclose(fout);
y = [y, fft_art_indices, S', E'];
save(fullfile(WORKSPACE.cur_pathname,DEFAULTS.output_pathname,filename_out),'y','-tabs','-ASCII','-append');
if(~STATE.batch_process_running)
    waitbar(100,h,'Saving complete');
    delete(h);
end;
sprintf('%i %0.2f-second FFTs saved to %s\r\n',rows,PSD.FFT_window_sec,filename_out)

