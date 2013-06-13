function [metricsOut,summaryOut] = sql_paramStruct2metrics(paramStruct,patstudykeys,stage_vec,metricsIn,summaryIn)
% [metricsOut,summaryOut] = sql_paramStruct2metrics(paramStruct,patstudykeys,stage_vec,metricsIn,summaryIn)
%
% read it and weep, or gnash your teeth, or whatever
%
% written by Hyatt Moore, IV
% May 16, 2013



fields = fieldnames(paramStruct);

%add new metrics as fields to the existing metricsIn structure
if(nargin>=4&&~isempty(metricsIn))
    metricsOut = metricsIn;
end
if(nargin>=5&&~isempty(summaryIn))
    summaryOut = summaryIn;
end

[u_keys,i,j ]= unique(patstudykeys);
%unique_keys == pastudykeys(i);
%patstudykeys = unique_keys(j);

%create a matrix of indices for each unique patstudykey
mg = meshgrid(1:numel(u_keys),1:numel(j));
mj = repmat(j,1,numel(u_keys));
key_ind_mat = mg==mj;



for f=1:numel(fields)
    fname = fields{f};
    mean_y = nan(numel(u_keys),1);

    for u_ind = 1:numel(u_keys)
        mean_y(u_ind) = mean(paramStruct.(fname)(key_ind_mat(:,u_ind)));
    end

    metricsOut.(fname) = mean_y;

    summaryOut.(fname) = getSummary(metricsOut.(fname));
end

% Code test case:
% x = [1 2 3 4 5 6 7 2 3 44 5  10]';  %sample values
% y = [4 4 4 1 1 1 2 2 2 30 30 1 ]';  %sample keys
% 
% [u,i,j] = unique(y);    
% mg = meshgrid(1:numel(u),1:numel(j));
% mj = repmat(j,1,numel(u));
% key_ind_mat = mg==mj;
% mean_y = zeros(numel(u),1);
% for u_ind = 1:numel(u)
%     mean_y(u_ind) = mean(x(key_ind_mat(:,u_ind)));
% end

