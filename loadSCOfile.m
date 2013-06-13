function SCO = loadSCOfile(filename)
%loads/parses the .SCO file associated with the EDF.
%SCO is a struct with the fields
% .epoch - the epoch that the scored event occured in
% .start_stop_matrix - the sample point that the events begin and end on
% .label - the string label used to describe the event
% .duration_seconds = the duration of the event in seconds (default is 1
% second)
% .start_time - events start time as a string in hour:minute:second format
% filename = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/A0097_4 174733.SCO';
% filename = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/A0210_3 170424.SCO';
% SCO = loadSCOfile(filename)
%  [ul,ui,uj] = unique(SCO.label); lm_epochs = SCO.epoch(3==uj,:); lm_evts = SCO.start_stop_matrix(3==uj,:); %obtains the unique epochs for the third
% unique event

% Hyatt Moore IV (< June, 2013)
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
%  3. last argument to textscan schanged to a regular expression since new
%  files had extra columns at the end which are causing problems with the
%  imports.

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
    neg = x{2}<0;
    
    if(any(neg))
        x{2}(neg) = abs(floor(x{2}(neg)/100));
        x{3}(neg) = abs(floor(x{3}(neg)/100));
    end
    
    x{3}(x{3}==0)=300; %make the default be 1.5 second duration.
    x{3}(isnan(x{3}))=300; %make the default be 1.5 second duration - typical case for Leg Movement to not have a value listed...

    EDF_filename = [filename(1:end-3),'EDF'];

    if(exist(EDF_filename,'file'))
        HDR = loadHDR(EDF_filename);
        samplerate = mode(HDR.samplerate);
        conversion_factor=100/samplerate;
    else
        samplerate = 100;
        conversion_factor = 1;
    end
    
    SCO.start_stop_matrix = floor([x{2},x{2}+x{3}]*conversion_factor/2); %remove any problems with the 0.5 indexing that can occur here


    SCO.duration_seconds = x{3}/samplerate;
    SCO.start_time = x{7};
    SCO.label = deblank(x{5});
    fclose(fid);
else
    SCO = [];
    disp('filename does not exist');
end


end