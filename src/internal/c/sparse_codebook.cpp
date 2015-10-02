#include "calc_codebook.h"

#pragma weak mxIsScalar

bool mxIsScalar(const mxArray *array_ptr);

void mexFunction(int num_out, mxArray *outParams[],
                 int num_in, const mxArray *inParams[]) {
    if(num_in != 3) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:num_in",
                          "3 Inputs required");
    }

    if(num_out != 1) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:num_out",
                          "1 Output required");
    }

    const mxArray* integral = inParams[0];
    const mxArray *tree;
    int xfield, yfield;

    if(!mxIsStruct(integral) || !mxIsScalar(inParams[1]) || !mxIsScalar(inParams[2])
       || !mxIsUint32(inParams[1]) || !mxIsUint32(inParams[2])) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_datatype",
                          "Param datatypes: (struct, uint32-scalar, uint32-scalar)");
    }

    if(!(tree = mxGetField(integral, 0, "tree")) ||
       -1 == (xfield = mxGetFieldNumber(tree, "x")) ||
       -1 == (yfield = mxGetFieldNumber(tree, "y"))) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_integral",
                          "Field(s) tree.x or/and tree.y missing");
    }

    int cbs = mxGetNumberOfElements(tree);
    eprintf("#Elements: %d\n", cbs);
    eprintf("X-Field: %d Y-Field: %d\n", xfield, yfield);
    uint32_t queryX = mxGetScalar(inParams[1]);
    uint32_t queryY = mxGetScalar(inParams[2]);
    outParams[0] = mxCreateDoubleMatrix(cbs, 1, mxREAL);
    double *codebook = mxGetPr(outParams[0]);

    calc_codebook(tree, xfield, yfield, queryX, queryY, codebook, cbs);
}

bool mxIsScalar(const mxArray *array_ptr) {
    return mxGetM(array_ptr) == mxGetN(array_ptr) == 1;
}
