#include "mex.h"

fill_matrix(double* outmatrix, size_t x, size_t y, size_t dim, double score, mwSize* dims) {
    size_t i, j;
    for(i = x-1; i < dims[1]; i++) {
        for(j = y-1; j < dims[2]; j++) {
            outmatrix[dims[0] * (i + j * dims[1])] += score;
        }
    }
}

void mexFunction(int num_out, mxArray *outParams[],
                 int num_in, const mxArray *inParams[]) {
    if(num_in != 1) {
        mexErrMsgIdAndTxt("Thesis:reconstruct_matrix_by_overwrite:num_in",
                          "1 Inputs required");
    }

    if(num_out != 1) {
        mexErrMsgIdAndTxt("Thesis:reconstruct_matrix_by_overwrite:num_out",
                          "1 Output required");
    }

    const mxArray* integral = inParams[0]; /* remove const */

    if(!mxIsStruct(integral)) {
        mexErrMsgIdAndTxt("Thesis:reconstruct_matrix_by_overwrite:invalid_datatype",
                          "Param datatypes: (struct)");
    }


    mxArray* scores = mxGetField(integral, 0, "scores");
    mxArray* coords = mxGetField(integral, 0, "coords");
    mxArray* I_size = mxGetField(integral, 0, "I_size");

    double* s = mxGetPr(scores);
    size_t nelem = mxGetM(scores);
    fprintf(stderr, "#Elements: %d\n", nelem);
    double* c = mxGetPr(coords);
    double* size = mxGetPr(I_size);
    size_t dimcnt = mxGetNumberOfElements(I_size);
    if(dimcnt == 4) {
        dimcnt--;
        size++;
    }
    mwSize dims[] = {size[0], size[1], size[2]};
    fprintf(stderr, "%dx%dx%d\n", dims[0], dims[1], dims[2]);

    outParams[0] = mxCreateNumericArray(dimcnt, dims, mxDOUBLE_CLASS, mxREAL);
    double* outmatrix = mxGetPr(outParams[0]);

    size_t i;
    for(i = 0; i < nelem; i++) {
        fill_matrix(outmatrix, c[i], c[i+nelem], c[i+nelem*2], s[i], dims);
    }
}
