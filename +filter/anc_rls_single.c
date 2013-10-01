//compile instructions: Type the following at the command line in the directory containing this file.
//mex anc_rls_single.c

#include "mex.h"
void mexFunction(int nlhs, mxArray *plhs[], 
    int nrhs, const mxArray *prhs[]){
    //input will be (signal, ref_signal,order,sigma,lambda)
    
    int i, j, n, rows, cols, row, col,col2,num_references,vector_size;
    int M; //%number of weights for the filter; why 4?  because I like the number 4, and He. found that after 3 things are fine.
    
//see following example for reference
    //edit([matlabroot '/extern/examples/mex/mexget.c']);
//   mxArray *signalArray, noiseArray;

    double sigma_inv;
    double lambda_inv;
    
    //http://publications.gbdirect.co.uk/c_book/chapter6/initialization.html
    double **Rinv, **Result,**RinvTmp;//eye(2*M)/sigma;   %Rinv is the [R(n-1)]^-1
    double *H; //%contains weights of both filters (hv and hh = horizontal and vertical)
    double *K;
    double Kdenom; //denominator scalar and numerator vector which hold the
    double *Knumer; //values necessary here...
    double rHprod; // r'*H product
  
    
    double *sig1,*noise1, *e; //s = signal+noise, n1 = noise ref 1, n2 = noise ref 2 (if applicable), e = cleaned signal
    double    lambda;// %forgetting factor; He. found values between 0.995 and 1.0 to produce similarly good result
    double sigma;
    double e_n;
    
    //check the input and output variables
    if (nlhs<1 || nrhs<3){
        mexErrMsgTxt("Function requires one output vector and at least two input vectors: 1. signal+noise; 2-n. noise reference(s)");
    }
    num_references = 1; //this is the case for anc_rls_single...mxGetPr(prhs[0])[0];
    
    if(nrhs>num_references+1){
        M = (int)mxGetScalar(prhs[num_references+1]);
    }
    else{
        M = 4;
        
    }
    
    if(nrhs>num_references+2)
        sigma = (double)mxGetScalar(prhs[num_references+2]);
    else
        sigma = 0.01;
    if(nrhs>num_references+3)
        lambda = (double)mxGetScalar(prhs[num_references+3]);
//         lambda = mxGetPr(prhs[num_references+3])[0];
    else
        lambda = 0.995;
//     printf("num references=%i\tM=%i\tSigma=%0.3f\tLambda=%0.3f\n",num_references,M,sigma,lambda);
    
    sigma_inv = 1/sigma;
    lambda_inv = 1/lambda;
    
    vector_size =  num_references*M;//(nrhs-1)*M;
    //http://publications.gbdirect.co.uk/c_book/chapter6/initialization.html
    
    //initialize memory

    Rinv = (double **)malloc(vector_size*sizeof(double*));
    Result = (double **)malloc(vector_size*sizeof(double*));
    RinvTmp= (double **)malloc(vector_size*sizeof(double*));

    H = (double*) malloc(vector_size*sizeof(double)); //%contains weights of both filters (hv and hh = horizontal and vertical)
    K = (double*) malloc(vector_size*sizeof(double));
    Knumer= (double*) malloc(vector_size*sizeof(double)); //values necessary here...
    
    //    printf("Vector size = %i\nSigma = %0.3f\tLambda = %0.3f\n",vector_size,sigma,lambda);
    for(i=0;i<vector_size;i++){
        Rinv[i] = (double*) malloc(vector_size*sizeof(double));
        Result[i] = (double*) malloc(vector_size*sizeof(double));
        RinvTmp[i] = (double*) malloc(vector_size*sizeof(double));
        
        for(j=0;j<vector_size;j++){
            Rinv[i][j]=0;
        }
        Rinv[i][i]=sigma_inv;
        H[i] = 0;
    }
    
    /* Find the dimensions of the data */
    rows = mxGetM(prhs[0]);
    cols = mxGetN(prhs[0]);
    
    /* Create an mxArray for the output data to be same size as input data*/
    plhs[0] = mxCreateDoubleMatrix(rows, cols, mxREAL);
    
    /* Create a pointer to the output data */
    e = mxGetPr(plhs[0]);
    
    /* Retrieve the input data */
//    signalArray = mxDuplicateArray(prhs[0]);
//    noiseArray = mxDuplicateArray(prhs[1]);
    
    //This was the old way of doing it, but needed to change so that I wasn't dealing with pass
    //by reference bugs from changing the data here
    sig1 = mxGetPr(prhs[0]);
    noise1 = mxGetPr(prhs[1]);
    
    
    /* Put data in the output array */
//  for (j = 0; j < rows*cols; j++) {
//      e[j] = 2 * n[j];
//  }
    
    for (n=0; n<rows*cols-(M-1);n++){  // Rinv is nrhs*M x nrls*M
        Kdenom = 0;
        rHprod = 0;
        for(row = 0; row<vector_size;row++){
            for(col = 0; col<vector_size;col++){
                Kdenom+=noise1[col+n]*Rinv[col][row]*noise1[row+n]; //r[row] = noise[row+n]
                Knumer[row]+=Rinv[row][col]*noise1[col+n]; //%either way worksp
                // Knumer[col]+=Rinv[col][row]*noise1[row+n];
            }
            rHprod+=noise1[row+n]*H[row];
        }
        Kdenom = Kdenom+lambda;
        e_n = sig1[n+(M-1)]-rHprod;
        rHprod = 0;
        for(row = 0; row<vector_size;row++){
            K[row] = Knumer[row]/Kdenom;
            Knumer[row] = 0; //reset this for next iteration (above)
            H[row] += K[row]*e_n;
            rHprod+=noise1[row+n]*H[row];
            
            for(col = 0; col<vector_size;col++){
                if(row==col){
                    RinvTmp[row][col]=lambda_inv*(1-K[row]*noise1[col+n]);
                }
                else{
                    RinvTmp[row][col]=-lambda_inv*K[row]*noise1[col+n];
                }
            }
            for(col = 0; col<vector_size;col++){
                Result[row][col]=0;
                for(col2 = 0; col2<vector_size;col2++){
                    Result[row][col] += RinvTmp[row][col2]*Rinv[col2][col];
                }
            }
            
        }
        for(row = 0; row<vector_size;row++){
            for(col = 0; col<vector_size;col++){
                Rinv[row][col] = Result[row][col];
            }
        }
        e[n+(M-1)] = sig1[n+(M-1)]-rHprod;
        
    }

    //free up allocated memory
    for(i=0;i<vector_size;i++){
        free(Rinv[i]);
        free(Result[i]);
        free(RinvTmp[i]);        
    }
    
    // the following creates problems, so leave commented for now
    //    free(Rinv);
    //    free(Result);
    //    free(RinvTmp);
    
    free(H);
    free(K);
    free(Knumer);
}


/*function e = anc_rls(sig,ref1,ref2)
 * % function e = anc_rls(sig,ref1,ref2)
 * % Adaptive noise canceller based on recursive least squares algorithm as
 * % developed/expounded on in P. He paper, "Removal of ocular artifracts from
 * % electro-encephalogram by adaptive filtering" - Medical and Biological
 * % Engineering and Computing 2004, Vol. 42
 * %
 * % e = cleaned output signal
 * % sig = input signal contaminated by noise from reference signals ref1 and ref2
 * %
 * %
 * % written by Hyatt Moore IV, February 28, 2012
 * %
 *
 *
 * if(nargin==3)
 *
 * %make sure we are dealing with row vectors
 * [r,c] =size(sig);
 *
 * if(r<c)
 * sig = sig.';
 * ref1 = ref1.';
 * ref2 = ref2.';
 * end
 *
 *
 * %(a) set initial values
 * lambda = 0.995; %forgetting factor; He. found values between 0.995 and 1.0 to produce similarly good result
 * lambda_inv = 1/lambda;
 * M = 4; %number of weights for the filter; why 4?  because I like the number 4, and He. found that after 3 things are fine.
 * sigma = 0.01;
 * Rinv = eye(2*M)/sigma;   %Rinv is the [R(n-1)]^-1
 * H = zeros(M*2,1);  %contains weights of both filters (hv and hh = horizontal and vertical)
 *
 * e = zeros(size(sig));
 *
 *
 * for n=M:numel(sig)
 * r = [ref1(n-M+1:n);ref2(n-M+1:n)];
 * K = (Rinv*r)/(lambda+r'*Rinv*r);
 * e_n = sig(n)-r'*H;
 * H = H+K*e_n;
 * Rinv = lambda_inv*Rinv-lambda_inv*K*r'*Rinv;
 * e(n) = sig(n)-r'*H;
 * end
 *
 * elseif(nargin==2)
 *
 * %make sure we are dealing with row vectors
 * [r,c] =size(sig);
 *
 * if(r<c)
 * sig = sig.';
 * ref1 = ref1.';
 * end
 *
 *
 * %(a) set initial values
 * lambda = 0.995; %forgetting factor; He. found values between 0.995 and 1.0 to produce similarly good result
 * lambda_inv = 1/lambda;
 * M = 4; %number of weights for the filter; why 4?  because I like the number 4, and He. found that after 3 things are fine.
 * sigma = 0.01;
 * Rinv = eye(M)/sigma;   %Rinv is the [R(n-1)]^-1
 * H = zeros(M,1);  %contains weights of both filters (hv and hh = horizontal and vertical)
 *
 * e = zeros(size(sig));
 *
 *
 * for n=M:numel(sig)
 * r = ref1(n-M+1:n);
 * K = (Rinv*r)/(lambda+r'*Rinv*r);
 * e_n = sig(n)-r'*H;
 * H = H+K*e_n;
 * Rinv = lambda_inv*Rinv-lambda_inv*K*r'*Rinv;
 * e(n) = sig(n)-r'*H;
 * end
 *
 * end*/