%> @file CLASS_WSC_database.m
%> @brief loads/parses the .SCO file associated with the EDF.
%> @brief SCO = loadSCOfile(filename)
% ======================================================================
%> @param filename
%> @param dest_samplerate Sample rate to use for SCO fields (return value)
%> @param sco_samplerate The SCO file's internal samplerate used internal =
%> this the sample rate used when generating the SCO file initially.
%> Typically the samplerate is twice the highest sampling rate used for the .EDF
%> channels as shown in the .EDF header.
%> @retval SCO is a struct with the fields
%> @li .epoch - the epoch that the scored event occured in
%> @li .start_stop_matrix - the sample point that the events begin and end on
%> @li .label - the string label used to describe the event
%> @li .duration_seconds = the duration of the event in seconds (default is 1
%> second)
%> @li .start_time - events start time as a string in hour:minute:second format
%> @param 
%> @note [ul,ui,uj] = unique(SCO.label); lm_epochs = SCO.epoch(3==uj,:); lm_evts = SCO.start_stop_matrix(3==uj,:); %obtains the unique epochs for the third
%> unique event

function SCO = loadSCOfile(filename,dest_samplerate, sco_samplerate)
%> filename = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/A0097_4 174733.SCO';
%> filename = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/A0210_3 170424.SCO';
% Hyatt Moore IV (< June, 2013)
%
% modified: 4/30/2014
%  1.  Added additional input arguments, dest_samplerate and sco_samplerate
%  to help with conversion.  Defaults are dest_samplerate = 100 and
%  sco_samplerate = 200
%  2.  Previously the duration_sec column was only divided by 100Hz and not
%  200Hz, so durations could be 2x's as long if the sampling rate was not
%  100 Hz.  

% Note:  EDF_filename = [filename(1:end-3),'EDF'];

%     if(exist(EDF_filename,'file'))
%         HDR = loadHDR(EDF_filename);
%         samplerate = max(HDR.samplerate);
%         conversion_factor=100/samplerate;
%     else
%         samplerate = 100;
%         conversion_factor = 1;
%     end
% 
%
%
% modified: 2/6/12 - 
%  1.  Some .sco files had empty lines at the top, and we need to cruise
%  through these until something hits - so I do a getl until the scan
%  works, otherwise it will crash
%  2.  Some sco files do not convert correctly due to the sample rate being
%  done at 128.  The EDF is okay, but the SCO file needs to be converted
%  correctly as well.  The mode sample rate from the EDF hdr is used for
%  converting 
% modified 12/15/12 
%  3. last argument to textscan has changed to a regular expression since new
%  files had extra columns at the end which are causing problems with the
%  imports.

if(nargin<3 || isempty(sco_samplerate)|| sco_samplerate<0)
    sco_samplerate= 200;
end

if(nargin<2 || isempty(dest_samplerate)|| dest_samplerate<0)
    dest_samplerate= 100;
end

if(exist(filename,'file'))
    fid = fopen(filename,'r');
%     x = textscan(fid,'%f %f %f %f %s %f %s %f %*f','delimiter','\t');
%     x = textscan(fid,'%f %f %f %f %s %f %s %f %*[.]','delimiter','\t');
    x = textscan(fid,'%f %f %f %f %s %f %s %f %*[^\n]','delimiter','\t');
    if(isempty(x{1}))
        file_size_bytes = fseek(fid,0,'eof');
        if(file_size_bytes==0)
            disp(['File size of ',filename,' is 0.  Going to crash now.']);
        end
        while(isempty(x{1}) && ftell(fid)<file_size_bytes)
            fgetl(fid);
            x = textscan(fid,'%f %f %f %f %s %f %s %f %*f','delimiter','\t');
            disp(filename);
        end
    end
    %remove potential problem of empty first line
    try
    if(isnan(x{1}(1)))
        for k=1:numel(x)
            x{k} = x{k}(2:end);
        end
    end
    catch me
        disp(me);
    end
    SCO.epoch = x{1};
    
    %handle the negative case, which pops up for the more recent sco files
    %which were not converted correctly the first time...
    % - adjusted on 4/30/2014 reference M.Stubbs email sent August 5, 2011
    neg = x{2}<0;
    
    if(any(neg))
        x{2}(neg) = abs(floor(x{2}(neg)/100));
        x{3}(neg) = abs(floor(x{3}(neg)/100));
    end
    
    x{3}(x{3}==0)=300; %make the default be 1.5 second duration.
    x{3}(isnan(x{3}))=300; %make the default be 1.5 second duration - typical case for Leg Movement to not have a value listed...

%     EDF_filename = [filename(1:end-3),'EDF'];

%     if(exist(EDF_filename,'file'))
%         HDR = loadHDR(EDF_filename);
%         samplerate = max(HDR.samplerate);
%         conversion_factor=100/samplerate;
%     else
%         samplerate = 100;
%         conversion_factor = 1;
%     end
    
    conversion_factor = dest_samplerate/sco_samplerate;
    SCO.start_stop_matrix = floor([x{2},x{2}+x{3}]*conversion_factor); %remove any problems with the 0.5 indexing that can occur here

    SCO.duration_seconds = x{3}/sco_samplerate;
    SCO.start_time = x{7};
    SCO.label = deblank(x{5});
    fclose(fid);
else
    SCO = [];
    disp('filename does not exist');
end


end