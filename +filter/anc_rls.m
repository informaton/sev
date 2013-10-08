function e = anc_rls(src_index,ref_indices, optional_params)
% function e = anc_rls(src_index, ref_indices)
% Adaptive noise canceller based on recursive least squares algorithm as
% developed/expounded on in P. He paper, "Removal of ocular artifracts from
% electro-encephalogram by adaptive filtering" - Medical and Biological
% Engineering and Computing 2004, Vol. 42
%
% e = cleaned output signal
% sig = input signal contaminated by noise from reference signals ref1 and ref2
%
%
% written by Hyatt Moore IV, February 28, 2012
% updated: 10/29/12 - added samples2delay as an argument option
% updated: 9/13/12 - added parameter passing to the c functions
% modified: 10.16.2012 - updated optional_params argument
% modified: 12/10/12 - raw data passing now possible using
% numel(src_index>100)

global CHANNELS_CONTAINER;

if(numel(src_index)>100)
    sig = src_index;
else
    sig = CHANNELS_CONTAINER.getData(src_index);
end

% if(numel(ref_indices)>100)
%     ref = ref_indices;
% else
%     ref = CHANNELS_CONTAINER.getData(ref_indices);
% end

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin==3 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order = 4;
        params.sigma = 0.01; %trace initialization value
        params.lambda = 0.995; %forgetting factor
        params.samples2delay = 0;
        plist.saveXMLPlist(pfile,params);
    end
end

[nrows,ncols] = size(ref_indices);

if(ncols>1)
    ref = cell(1,ncols);

    %put this for multiple channels;
    
    for cols=1:ncols
        
%         ref{cols} = CHANNELS_CONTAINER.getData(ref_indices(cols));
        ref{cols} = filter.nlfilter_delay(ref_indices(:,cols), params);
        
    end
    disp([ref{1}(1:4),ref{2}(1:4)]);
    e = filter.anc_rls_multiple(sig,cell2mat(ref),params.order,params.sigma,params.lambda);
else
    
%     if(ncols<nrows)
%         ref_indices = ref_indices';
%     end

    
%     ref = CHANNELS_CONTAINER.getData(ref_indices);
    ref = filter.nlfilter_delay(ref_indices, params);
    
    %debugging
    %     debugging = false;
    %     if(debugging)
    % %         cd +filter;mex anc_rls_single.c; cd ..;
    %         e = filter.anc_rls_single(sig(1:100),ref(1:100),params.order,params.sigma,params.lambda);disp(e(1:10)');
    %
    %     end
    
    e = filter.anc_rls_single(sig,ref,params.order,params.sigma,params.lambda);  
    
    %run it again - some problem here that is not understood
    if(any(isnan(e(1:10))))
        e = filter.anc_rls_single(sig,ref,params.order,params.sigma,params.lambda);  
    end
end