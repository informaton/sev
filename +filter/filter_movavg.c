//compile instructions: Type the following at the command line in the directory containing this file.
//mex filter_movavg.c

#include "mex.h"
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, 
  const mxArray *prhs[]){
    //input will be (1, result, 2, signal, order)
    
    int i, j, k, rows, cols, num_references,vector_size, window_size;
    int order, N, M; //%number of weights for the filter; why 4?  because I like the number 4, and He. found that after 3 things are fine.
    
//see following example for reference
    //edit([matlabroot '/extern/examples/mex/mexget.c']);
//   mxArray *signalArray, noiseArray;

    double tempavg;
    double inv_ws;
    
    //http://publications.gbdirect.co.uk/c_book/chapter6/initialization.html
       
    double *sig1, *e; //s = signal+noise, n1 = noise ref 1, n2 = noise ref 2 (if applicable), e = cleaned signal

    
    //check the input and output variables
    if (nlhs<1 || nrhs<1){
        mexErrMsgTxt("Function requires one output vector and at least two input vectors: 1. signal+noise; 2-n. noise reference(s)");
    }
    num_references = 1; //this is the case for anc_rls_single...mxGetPr(prhs[0])[0];
    //printf("nrhs= %d", nrhs);
    if(nrhs>num_references){
        M = (int)mxGetScalar(prhs[num_references]);
        //printf("M is now %u\n",M);
    }
    else{
        M = 4;
        
    }
    
   
   
//     printf("num references=%i\tM=%i\tSigma=%0.3f\tLambda=%0.3f\n",num_references,M,sigma,lambda);
    

    
    vector_size =  num_references*M;//(nrhs-1)*M;
    //printf("vector size = %u\n",vector_size);
    //http://publications.gbdirect.co.uk/c_book/chapter6/initialization.html
   
    window_size=M;
    
    //printf("window size = %d \n", window_size);
    inv_ws=1.0/(double)window_size;
    //printf("inverse window size= %f \n", inv_ws);
    
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
    
    N=cols;
    //printf("M= %d N= %d \n", M, N);
    
   //for (i=0;i<N;i++){
   //     sig1[i]=(double)i;
   //     printf ("%f %d", sig1[i], i);
   //}
    
    
    tempavg=0;
    for (j=0;j<window_size; j++){
        tempavg=tempavg+(double)sig1[j];
        //printf("tempavg: %f \n", tempavg);
    } 
    tempavg=tempavg*inv_ws;
    
    e[0]=tempavg;
    
    i=1;
    for (k=1; k<=N-window_size; k++){
        //printf("k = %d \n", k);
        tempavg=tempavg-inv_ws*sig1[k-1]+inv_ws*sig1[k+window_size-1];
        e[i]=tempavg;
        //printf("e: %f \n", e[i]);
        i++;
    }
}
