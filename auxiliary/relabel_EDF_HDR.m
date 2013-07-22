function relabel_EDF_HDR(edf_filename, new_labels,label_indices)
%new_labels = cell of label names
%label_indices = vector of indices (1-based) of the label to be replaced in
%the EDF header
%Author: Hyatt Moore IV
%10.18.2012
if(exist(edf_filename,'file'))
    fid = fopen(edf_filename,'r+');
    
    fseek(fid,252,'bof');
    number_of_channels = str2double(fread(fid,4,'*char')');
    label_offset = 256; %ftell(fid);
    out_of_range_ind = label_indices<1 | label_indices>number_of_channels;
    label_indices(out_of_range_ind) = [];
    new_labels(out_of_range_ind) = [];
    num_labels = numel(new_labels);
    label_size = 16; %16 bytes

    for k=1:num_labels
        numChars = min(numel(new_labels{k}),label_size);
        new_label = repmat(' ',1,label_size);
        new_label(1:numChars) = new_labels{k}(1:numChars);
        fseek(fid,label_offset+(label_indices(k)-1)*label_size,'bof');
        fwrite(fid,new_label,'*char');
    end
    fclose(fid);
end
