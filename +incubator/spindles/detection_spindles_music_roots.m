function detectStruct = detection_spindles_music_roots(source_index,optional_params)
%want to detect the two largest roots as obtained from music root function
%rootmusic();

global CHANNELS_CONTAINER;

global BATCH_PROCESS;

%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else   
    pfile = '+detection/detection_spindles_music_roots.plist';
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        params.low_freq_start = 2;
        params.low_freq_end = 4;
        params.high_freq_start = 12;
        params.high_freq_end = 15;
        params.num_roots = 2;
        params.interval_sec = 0.5;
        params.power_threshold = 40;
        plist.saveXMLPlist(pfile,params);        
    end
end

ranges = [params.low_freq_start, params.low_freq_end;
    params.high_freq_start, params.high_freq_end];

% CHANNEL = CHANNELS_CONTAINER.cell_of_channels{source_index};
CHANNEL.data = CHANNELS_CONTAINER.getData(source_index);
CHANNEL.sample_rate = CHANNELS_CONTAINER.getSamplerate(source_index);


samples_per_interval = params.interval_sec*CHANNEL.sample_rate;

num_samples = numel(CHANNEL.data);
num_intervals = floor(num_samples/samples_per_interval);

%figure out where to save this stuff
filename = '';

if(isfield(BATCH_PROCESS,'cur_filename'))
    studyname = strtok(BATCH_PROCESS.cur_filename,' ');
    filename = fullfile(BATCH_PROCESS.output_path,['m_roots.',studyname,'.mat']);
end

if(isempty(filename))
    filename = 'm_roots.tmp.mat';
end;
if(exist(filename,'file'))
    data = load(filename);
    m_roots = data.m_roots;
    m_pow = data.m_pow;
    start_stop_matrix = data.start_stop_matrix;
else
    m_roots = zeros(num_intervals,params.num_roots);
    m_pow = zeros(num_intervals,params.num_roots);
    start_stop_matrix = zeros(num_intervals,2);   %this will contain the start and stop sample points for each interval - mainly so I can includ e theparamStruct parameters *i.e. the roots* in the output file
    range = 1:samples_per_interval;
    h = waitbar(0,'calculating music roots');
    tic
    for k=1:num_intervals
        start_stop_matrix(k,:) = [range(1), range(end)];
        data = CHANNEL.data(range);
        X = corrmtx(data,12,'mod');
%         [F,POW] = rootmusic(data,params.num_roots*2,CHANNEL.sample_rate);
        [F,POW] = rootmusic(X,params.num_roots*2,CHANNEL.sample_rate);
        
        
        %POW = POW(POW>0);
        try
            m_roots(k,:) = F(F>0);
            m_pow(k,:) = POW(1:2)*2; %need to increase this we are taking 1/2 the frequencies (only the positive freqs)
        catch ME
            disp 'an error was caught at counter k = ';
            disp(k);
            
        end
        
        
        range = range+samples_per_interval;
        
        if(mod(k,1000)==1)
            waitbar(k/num_intervals,h);
            drawnow();
        end
        
    end
    toc
    
    save(filename,'m_roots','m_pow','start_stop_matrix','-mat');
    delete(h);

end

m_roots = sort(m_roots,2,'ascend');
% m_pow = m_pow(indices);
good_roots = (m_roots(:,1)>ranges(1,1)) & (m_roots(:,1)<ranges(1,2)) & ...
    (m_roots(:,2)>ranges(2,1)) & (m_roots(:,2)<ranges(2,2));

good_pow = m_pow(:,1)>params.power_threshold &m_pow(:,2)>params.power_threshold;
good_ind = good_roots&good_pow;

disp(['Good roots =',num2str(sum(good_roots))]);
disp(['Good pow =',num2str(sum(good_pow))]);
disp(['both good pow =',num2str(sum(good_ind))]);

detectStruct.new_data = [];



detectStruct.new_events = start_stop_matrix(good_ind,:);
m_roots = m_roots(good_ind,:);
m_pow = m_pow(good_ind,:);
paramStruct.m_root_1 = m_roots(:,1);
paramStruct.m_root_2 = m_roots(:,2);
paramStruct.m_pow_1 = m_pow(:,1);
paramStruct.m_pow_2 = m_pow(:,2);

detectStruct.paramStruct = paramStruct;