#include <stdint.h>
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

    if(!mxIsUint32(integralPoints) || mxGetN(integralPoints) != 3) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_points",
                          "Point array must be Nx3 uint32");
    }

    if(!mxIsDouble(integralScores) || mxGetN(integralScores) != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_points",
                          "Scores must be col vector");
    }

    if(!mxIsUint32(queryPoints) || mxGetN(queryPoints) != 2 || mxGetM(queryPoints) != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_query_point",
                          "Query 1x2 uint32");
    }

    if(mxGetM(integralScores) != mxGetM(integralPoints)) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_data",
                          "Scores and points must have same size");
    }

    if(!mxIsDouble(codebookSize) || mxGetNumberOfElements(codebookSize) != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_codebook_size",
                          "Codebooks size is a non-scalar");
    }



    uint32_t *ip = (uint32_t*)mxGetPr(integralPoints);
    double *scores = mxGetPr(integralScores);
    double *qp = mxGetPr(queryPoints);
    double cbs = mxGetScalar(codebookSize);
    uint32_t queryX = qp[0];
    uint32_t queryY = qp[1];
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
    uint32_t* ip_y = ip + num_elements*2;
    for(i = num_elements; i >= 0; i--) {
        /*if(ip[i] <= queryX && ip[i+num_elements] <= queryY)*/
        if(ip_y[i] <= queryY)
            break;
    }
    uint32_t* ip_x = ip + num_elements;
#if 0
    printf("%d (%f, %f)\n", i, ip[i+num_elements], ip[i+num_elements*2]);
#endif
    for(j = 0; j <= i; j++) {
        /*printf("%.0f %d\n", ip[j + num_elements], ip[j + num_elements] <= queryX);*/
        if(ip_x[j] <= queryX)
            codebook[ip[j]-1] = scores[j];
    }
}
