function paramStruct = sql_params2struct(sql_q)
% paramStruct = sql_params2struct(sql_q)
% sql_q is a struct obtained from an mym sql query with fields params which
% is a struct of vectors which are all extracted one level out if they are
% in paramFnames

% written by Hyatt Moore, IV
% May 16, 2013

params = cell2mat(sql_q.params);
paramFnames = fieldnames(params(1));
paramCell = struct2cell(params); %convert to a P-by-M-by-N array from 

for m=1:numel(paramFnames)
    paramStruct.(paramFnames{m}) = cells2mat(paramCell{m,:});
end


% Code test case:
% sql_q = mym('select params from events_t where detectorid=143 and patstudykey in (1,2,3,4,5)');
% paramStruct = sql_params2struct(sql_q);
% if(paramStruct.auc(50)==sql_q.params{50}.auc)
%     disp('test passed');
% else
%     disp('test failed');
% end