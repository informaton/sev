function [HDR, signals] = writeEDF(filename, HDR, signals)
%Writes EDF files (not EDF+ format); if no HDR is specified then
%a "blank" HDR is used. If no signals are specified, 2 signals of 
%repeating matrices of 5000 and 10000 are used.

%written by Adam Rhine  (June, 2011)
if(nargin==0)
    disp 'No input filename given; aborting';
    return;
end;

if (nargin==1)  %If no HDR specified, blank HDR used instead
    HDR.ver = 0;
    HDR.patient = 'UNKNOWN';
    HDR.local = 'UNKNOWN';
    HDR.startdate = '01.01.11';
    HDR.starttime = '00.00.00';
    HDR.HDR_size_in_bytes = 768;
    HDR.number_of_data_records = 18522;
    HDR.duration_of_data_record_in_seconds = 1;
    HDR.num_signals = 1;
    HDR.label = {'Blank1'};
    HDR.transducer = {'unknown'};
    HDR.physical_dimension = {'uV'};
    HDR.physical_minimum = -250;
    HDR.physical_maximum = 250;
    HDR.digital_minimum = -2048;
    HDR.digital_maximum = 2047;
    HDR.prefiltering = {'BP: 0.1HZ -100HZ'};
    HDR.number_samples_in_each_data_record = 100;
end;

if(nargin<3)    %If no signals specified, fills with num_signals worth of repeating signals (5000 for first signal, 10000 for second, etc.)
    disp(HDR.num_signals);
    signals = cell(HDR.num_signals,1);
    for k=1:HDR.num_signals
        signals{k}=repmat(5000*k,1852200,1);
    end;
end;

if(nargin>3)
    disp('Too many input arguments in loadEDF.  Extra input arguments are ignored');
end;

fid = fopen(filename,'w');

%'output' becomes the header
output = resize(num2str(HDR.ver),8);
output = [output resize(HDR.patient,80)];
output = [output resize(HDR.local,80)];
output = [output resize(HDR.startdate,8)];
output = [output resize(HDR.starttime,8)];

%location is currently 160+24+1 ("1-based") = 185
output = [output resize(num2str(HDR.HDR_size_in_bytes),8)];
output = [output repmat(' ',1,44)]; %HDR.reserved
output = [output resize(num2str(HDR.number_of_data_records),8)];
output = [output resize(num2str(HDR.duration_of_data_record_in_seconds),8)];
output = [output resize(num2str(HDR.num_signals),4)];
output = [output rep_sig(HDR.label,16)];
output = [output rep_sig(HDR.transducer,80)];
output = [output rep_sig(HDR.physical_dimension,8)];
output = [output rep_sig_num(HDR.physical_minimum,8,'%1.1f')];
output = [output rep_sig_num(HDR.physical_maximum,8,'%1.1f')];
output = [output rep_sig_num(HDR.digital_minimum,8)];
output = [output rep_sig_num(HDR.digital_maximum,8)];
output = [output rep_sig(HDR.prefiltering,80)];
output = [output rep_sig_num(HDR.number_samples_in_each_data_record,8)];

ns = HDR.num_signals;



for k=1:ns
    output = [output repmat(' ',1,32)]; %reserved...
end;

HDR.HDR_size_in_bytes = numel(output);
output(185:192) = resize(num2str(HDR.HDR_size_in_bytes),8);

precision = 'uint8';
fwrite(fid,output,precision); %Header is written to the file

%Writes the signals to the file
% if(iscell(signals))
%     for k=1:ns
%         total_samples = total_samples+ numel(signals{k});
%     end
% else
%     total_samples =numel(signals);
% end
% A = zeros(1,total_samples); %column vector of data to store


%just do the whole thing slowly - at least we know it will work
for rec=1:HDR.number_of_data_records
    for k=1:ns
        samples_in_record = HDR.number_samples_in_each_data_record(k);
        
        range = (rec-1)*samples_in_record+1:(rec)*samples_in_record;
        if(iscell(signals))
            currentsignal = int16(signals{k}(range));
        else
            currentsignal = int16(signals(k,range));
        end
        fwrite(fid,currentsignal,'int16');
    end
end
% total_samples_per_record = sum(HDR.number_samples_in_each_data_record);
% disp(['header at ',num2str(ftell(fid))]);
% %go through the first records of each channel and write them to disk
% 
% 
% for k=1:ns
%     samples_in_record = HDR.number_samples_in_each_data_record(k);
% 
%     if(iscell(signals))
%         currentsignal = int16(signals{k}(1:samples_in_record));
%     else
%         currentsignal = int16(signals(k,1:samples_in_record));
%     end
% %     precision = [num2str(HDR.number_samples_in_each_data_record(k)),'*int16'];
%     fwrite(fid,currentsignal,'int16');
% end
% data_offset = ftell(fid);  %get to the current location now
% 
% %now, go through the remaining channels, with the ability to use the skip
% %method of fwrite (previously it would not go back far enough...
% bytes_per_sample = 2;
% for k=1:ns
%     samples_in_record = HDR.number_samples_in_each_data_record(k);
% 
%     if(iscell(signals))
%         currentsignal = int16(signals{k}(samples_in_record+1:end));
%     else
%         currentsignal = int16(signals(k,samples_in_record+1:end));
%     end
%     precision = [num2str(HDR.number_samples_in_each_data_record(k)),'*int16'];
%     samples_til_next_record = total_samples_per_record-samples_in_record;
%     fseek(fid,data_offset-samples_til_next_record*bytes_per_sample,'bof');
%     disp(ftell(fid));
%         
%     disp(fwrite(fid,currentsignal,precision,samples_til_next_record));
%     disp(ftell(fid));
%     data_offset = data_offset+samples_in_record*bytes_per_sample;
% 
% end


% fwrite(fid,A,'double=>int16');
%     
%     precision = [num2str(HDR.number_samples_in_each_data_record(k)),'*double=>',num2str(HDR.number_samples_in_each_data_record(k)),'*int16'];
% %     precision = 'double=>int16';
%     skip = (sum(HDR.number_samples_in_each_data_record)-HDR.number_samples_in_each_data_record(k))*2;
%     if (ns==1)
%         cur_offset = sum(HDR.number_samples_in_each_data_record)*2;
%     else
%         cur_offset = sum(HDR.number_samples_in_each_data_record(1:k-1))*2;
%     end
%     offset = HDR.HDR_size_in_bytes + cur_offset;
%     disp(HDR.HDR_size_in_bytes);
%     disp(offset);
%     disp(offset-sum(HDR.number_samples_in_each_data_record));
%     fseek(fid,offset-(sum(HDR.number_samples_in_each_data_record)),-1);
%     fwrite(fid,currentsignal,precision,skip);
% end

fclose(fid);
return;

% HEADER Specs...
% 8 ascii : version of this data format (0)') 
% 80 ascii : local patient identification (mind item 3 of the additional EDF+ specs)')
% 80 ascii : local recording identification (mind item 4 of the additional EDF+ specs)')
% 8 ascii : startdate of recording (dd.mm.yy)') (mind item 2 of the additional EDF+ specs)')
% 8 ascii : starttime of recording (hh.mm.ss)') 
% 8 ascii : number of bytes in header record 
% 44 ascii : reserved 
% 8 ascii : number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)') 
% 8 ascii : duration of a data record, in seconds 
% 4 ascii : number of signals (ns)') in data record 
% ns * 16 ascii : ns * label (e.g. EEG Fpz-Cz or Body temp)') (mind item 9 of the additional EDF+ specs)')
% ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)') 
% ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)') 
% ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)') 
% ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)') 
% ns * 8 ascii : ns * digital minimum (e.g. -2048)') 
% ns * 8 ascii : ns * digital maximum (e.g. 2047)') 
% ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)') 
% ns * 8 ascii : ns * nr of samples in each data record 
% ns * 32 ascii : ns * reserved



%Modifies a string ('input') to be as long as 'length', with blanks filling
%in the missing chars

function [resized_string] = resize(input,length)

resized_string = repmat(' ',1,length);

for k=1:numel(input)
    resized_string(k)=input(k);
end;

return;


%Same as resize(), but does so for all elements in a cell array
function [multi_string] = rep_sig(input,length)

multi_string = '';

for k=1:numel(input)
    multi_string = [multi_string resize(input{k},length)];
end;
return;



%Same as rep_sig(), but does so for all elements in a matrix of doubles
function [multi_string] = rep_sig_num(input,length,prec)

if (nargin<3)
    prec = '%1.0f';
end;

multi_string = '';

for k=1:numel(input)
    multi_string = [multi_string resize(num2str(input(k),prec),length)];
end;
return;


