#include "mex.h"



void mexFunction(int num_out, mxArray *outParams[],
                 int num_in, const mxArray *inParams[]) {
    if(num_in != 4) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:num_in",
                          "4 Inputs required");
    }

    if(num_out != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:num_out",
                          "1 Output required");
    }

    const mxArray* integralPoints = inParams[0];
    const mxArray* integralScores = inParams[1];
    const mxArray* queryPoints = inParams[2];
    const mxArray* codebookSize = inParams[3];
    mwSize num_elements = mxGetM(integralScores);
#if 0
    printf("#Elements: %d\n", num_elements);
#endif

    if(!mxIsDouble(integralPoints) || mxGetN(integralPoints) != 3) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_points",
                          "Point array must be Nx3");
    }

    if(!mxIsDouble(integralScores) || mxGetN(integralScores) != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_points",
                          "Scores must be col vector");
    }

    if(!mxIsDouble(queryPoints) || mxGetN(queryPoints) != 2 || mxGetM(queryPoints) != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_query_point",
                          "Query 1x2");
    }

    if(mxGetM(integralScores) != mxGetM(integralPoints)) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_data",
                          "Scores and points must have same size");
    }

    if(!mxIsDouble(codebookSize) || mxGetNumberOfElements(codebookSize) != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_codebook_size",
                          "Codebooks size is a non-scalar");
    }



    double *ip = mxGetPr(integralPoints);
    double *scores = mxGetPr(integralScores);
    double *qp = mxGetPr(queryPoints);
    double cbs = mxGetScalar(codebookSize);
    double queryX = qp[0];
    double queryY = qp[1];
    int i,j;

#if 0
    printf("Codebooksize: %.0f\n", cbs);
    printf("Query: (%.2f, %.2f)\n", queryX, queryY);
#endif

    outParams[0] = mxCreateDoubleMatrix(cbs, 1, mxREAL);
    double *codebook = mxGetPr(outParams[0]);

    /*
     * 0 - #el => cb
     * #el - 2*#el -> x
     * 2*#el - 3*#el -> y
     */
    for(i = num_elements*2 - 1; i >= num_elements; i--) {
        /*if(ip[i] <= queryX && ip[i+num_elements] <= queryY)*/
        if(ip[i+num_elements] <= queryY)
            break;
    }
    i -= num_elements;
#if 0
    printf("%d (%f, %f)\n", i, ip[i+num_elements], ip[i+num_elements*2]);
#endif
    for(j = 0; j <= i; j++) {
        /*printf("%.0f %d\n", ip[j + num_elements], ip[j + num_elements] <= queryX);*/
        if(ip[j + num_elements] <= queryX)
            codebook[(int)ip[j]-1] = scores[j];
    }
}
