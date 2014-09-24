%> @file anc_rls.cpp
%> @brief Recursive least squares implementation of adaptive noise cancellation.
%======================================================================
%> @brief Adaptive noise canceller based on recursive least squares algorithm as
%> developed/expounded on in P. He paper, "Removal of ocular artifracts from
%> electro-encephalogram by adaptive filtering" - Medical and Biological
%> Engineering and Computing 2004, Vol. 42
%
%> @param sig_data = input signal contaminated by noise from reference signal(s) - argument two
%> @param ref_data = input signal contaminated by noise from reference signal(s) - argument two
%> @param params Optional structure of field/value parameter pairs that to adjust filter's behavior.
%> @li %c .order Number of taps to use - suggest 4;  
%> @li %c .sigma Trace initialization value - suggest 0.01; 
%> @li %c .lambda Forgetting factor - suggest 0.995; 
%> @li %c .samples2delay Useful for correcting delayed correlation beyond filter size (i.e. number of taps) or when applying a self reference adaptive noise cancellation - use 0 for none;
%> @retval e = adaptively cleaned output signal -  the src_data with correlated ref_data interference removed.
%> @note This uses a mex compiled implementation for speed.
%> @note Last modified on 5/6/2014 - 
%> @note written by Hyatt Moore IV, February 28, 2012
%> @note updated: 10/29/12 - added samples2delay as an argument option
%> @note updated: 9/13/12 - added parameter passing to the c functions
%> @note modified: 10.16.2012 - updated optional_params argument
%> @note modified: 12/10/12 - raw data passing now possible usingfunction e = anc_rls(src_data,ref_data, optional_params)
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function e = anc_rls(sig_data, ref_data, params)

% initialize default parameters
defaultParams.order = 4;
defaultParams.sigma = 0.01; %trace initialization value
defaultParams.lambda = 0.995; %forgetting factor
defaultParams.samples2delay = 0;
% return default parameters if no input arguments are provided.
if(nargin==0)
    e = defaultParams;
else
    
    if(nargin<3 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future            
            params = defaultParams;
            plist.saveXMLPlist(pfile,params);
        end
    end
    
    
    
    [nrows,ncols] = size(ref_data);
    
    if(ncols>1)
        ref = cell(1,ncols);
        
        %put this for multiple channels;
        
        for cols=1:ncols
            
            %         ref{cols} = CHANNELS_CONTAINER.getData(ref_indices(cols));
            ref{cols} = filter.nlfilter_delay(ref_data(:,cols), params);
            
        end
        disp([ref{1}(1:4),ref{2}(1:4)]);
        %     e = filter.anc_rls_multiple(sig,cell2mat(ref),params.order,params.sigma,params.lambda);
        e = filter.anc_rls_single(sig_data,cell2mat(ref),params.order,params.sigma,params.lambda);
    else
        
        %     if(ncols<nrows)
        %         ref_indices = ref_indices';
        %     end
        
        
        %     ref = CHANNELS_CONTAINER.getData(ref_indices);
        ref = filter.nlfilter_delay(ref_data, params);
        
        %debugging
        %     debugging = false;
        %     if(debugging)
        % %         cd +filter;mex anc_rls_single.c; cd ..;
        %         e = filter.anc_rls_single(sig(1:100),ref(1:100),params.order,params.sigma,params.lambda);disp(e(1:10)');
        %
        %     end
        
        e = filter.anc_rls_single(sig_data,ref,params.order,params.sigma,params.lambda);
        
        %run it again - some problem here that is not understood
        if(any(isnan(e(1:10))))
            e = filter.anc_rls_single(sig_data,ref,params.order,params.sigma,params.lambda);
        end
    end
end