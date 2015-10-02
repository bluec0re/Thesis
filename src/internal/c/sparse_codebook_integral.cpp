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

    if(!mxIsStruct(integral) || 2 != mxGetM(inParams[1]) || 2 != mxGetM(inParams[2])
       || !mxIsUint32(inParams[1]) || !mxIsUint32(inParams[2])) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_datatype",
                          "Param datatypes: (struct, 2x1-uint32, 2x1-scalar)");
    }

    if(!(tree = mxGetField(integral, 0, "tree")) ||
       -1 == (xfield = mxGetFieldNumber(tree, "x")) ||
       -1 == (yfield = mxGetFieldNumber(tree, "y"))) {
        mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_integral",
                          "Field(s) tree.x or/and tree.y missing");
    }

    int i, cbs = mxGetNumberOfElements(tree);
    eprintf("#Elements: %d\n", cbs);
    uint32_t* queryX = (uint32_t*)mxGetPr(inParams[1]);
    uint32_t* queryY = (uint32_t*)mxGetPr(inParams[2]);
    outParams[0] = mxCreateDoubleMatrix(cbs, 1, mxREAL);
    double *codebook = mxGetPr(outParams[0]);
    double *a = new double[cbs];
    double *b = new double[cbs];
    double *c = new double[cbs];
    double *d = new double[cbs];

    // very bad results??
    calc_codebook(tree, xfield, yfield, queryX[0], queryY[0], a, cbs);
    calc_codebook(tree, xfield, yfield, queryX[1], queryY[0], b, cbs);
    calc_codebook(tree, xfield, yfield, queryX[0], queryY[1], c, cbs);
    calc_codebook(tree, xfield, yfield, queryX[1], queryY[1], d, cbs);

    for(i = 0; i < cbs; i++) {
        codebook[i] = (a[i] + d[i]) - (b[i] + c[i]);
    }
}
