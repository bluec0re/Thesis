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


    size_t dim_size = size[0];
    size_t height = size[2];
    size_t width  = size[1];


    size_t dx = dim_size * width;
    size_t total = dx * height;
    size_t previous = total - dim_size;

    size_t i = 0;

    /*
    int d,x,y;
    double *tmp1, *tmp2, *tmp3;
    for(y = 1; y < height; y++) {
        tmp1 = outmatrix + y*dx;
        for(x = 1; x < width; x++) {
            tmp2 = tmp1 + x * dim_size;
            for(d = 0; d < dim_size; d++) { /* codebook dimensions * /
                tmp3 = tmp2 + d;
                if(tmp3[0] == 0 && tmp3[-dim_size] != 0) {
                    fprintf(stderr, "(%lu,%lu) = %f\n", x-1, y, tmp3[-dim_size]);
                    tmp3[0] = tmp3[-dim_size];
                }
            }
        }
    }
*/


    for(i = dx /* skip first line */; i < total; i++) {
        if(outmatrix[i] == 0 && (i % dx) >= dim_size /* skip first col */ && outmatrix[i - dim_size] != 0) {
            outmatrix[i] = outmatrix[i - dim_size];
        }
    }
}
