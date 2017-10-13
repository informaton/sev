function emd_n = getEMD(data,n)
%n is the level to get of the emd (with n decompositions)
%data is the data to be decomposed
%emd_n is the emd of data at level n
global DEFAULTS;


epoch_size_samples = DEFAULTS.standard_epoch_sec*DEFAULTS.fs;
emd_n = zeros(size(data));

% frequency = zeros(size(data));
% amplitude = zeros(size(data));

h = waitbar(0,'Calculating HHT','name','getEMD.m');
start_time = now;
num_epochs = floor(numel(data)/epoch_size_samples);
tic
for cur_epoch=1:num_epochs
    first_index_of_current_epoch = (cur_epoch-1)*epoch_size_samples+1;
    last_index_of_current_epoch = first_index_of_current_epoch+epoch_size_samples-1;
    range = first_index_of_current_epoch:last_index_of_current_epoch;

    imf = emd_slow(data(range),n);
    emd_n(range) = imf{end};
    clear imf;

%     %lose two indices when using hhspectrum (first and last are lost)
%     [amplitude(range(2:end-1)),frequency(range(2:end-1))] = hhspectrum(imf1(range));
    waitbar(cur_epoch/num_epochs,h,['Completed epoch ' num2str(cur_epoch) ' of ' num2str(num_epochs) '.  Elapsed time: ' datestr(now-start_time,'HH:MM:SS')]);

end

if(ishandle(h))
    delete(h);
end;