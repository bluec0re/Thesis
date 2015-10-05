#include "mex.h"



void mexFunction(int num_out, mxArray *outParams[],
                 int num_in, const mxArray *inParams[]) {
    if(num_in != 1) {
        mexErrMsgIdAndTxt("Thesis:reconstruct_matrix:num_in",
                          "1 Inputs required");
    }

    if(num_out != 1) {
        mexErrMsgIdAndTxt("Thesis:reconstruct_matrix:num_out",
                          "1 Output required");
    }

    mxArray* inmatrix = (mxArray*)inParams[0]; /* remove const */

    if(!mxIsDouble(inmatrix)) {
        mexErrMsgIdAndTxt("Thesis:reconstruct_matrix:invalid_datatype",
                          "Param datatypes: (DxXxY)");
    }

    outParams[0] = inmatrix;
    double *outmatrix = mxGetPr(outParams[0]);
    const mwSize *size = mxGetDimensions(inmatrix);
    if(mxGetNumberOfDimensions(inmatrix) == 4)
        size++;
    fprintf(stderr, "%dx%dx%d\n", size[0], size[1], size[2]);
    mxUnshareArray(inmatrix, true);



    size_t i = 0;
    /*int d,x,y;
    for(d = 0; d < size[0]; d++) { /* codebook dimensions * /
        for(x = 1; x < size[1]; x++) {
            for(y = 1; y < size[2]; y++) {
                i = y * size[0] * size[1] + x * size[0] + d;
                if(!outmatrix[i]) {
                    outmatrix[i] = outmatrix[i - size[0] * size[1] - size[0]];
                }
            }
        }
    }*/
    size_t dx = size[0] * size[1];
    size_t total = dx * size[2];
    size_t previous = total - size[0];
    for(i = dx /* skip first line */; i < total; i++) {
        if(!outmatrix[i] && (i % dx) > size[0] /* skip first col */) {
            outmatrix[i] = outmatrix[i - previous];
        }
    }
}
