#include "mex.h"
#include <string.h>
#include <stdint.h>
#include <math.h>

#pragma weak mxIsScalar
bool mxIsScalar(const mxArray *array_ptr);

#ifndef nullptr
    #define nullptr 0
#endif

template<typename T>
T* binsearch(T* start, T* end, T rangeStart, T rangeEnd) {
    if(*start >= rangeStart && *start <= rangeEnd) {
        return start;
    } else if(*start > rangeEnd || *end < rangeStart) {
        return nullptr;
    } else if(*end >= rangeStart && *end <= rangeEnd) {
        return end;
    } else if(rangeStart > rangeEnd) {
        printf("%f > %f\n", rangeStart, rangeEnd);
        return nullptr;
    }

    T* current;
    while(start < end) {
        current = start + (end - start) / 2;
        if(rangeStart <= *current && *current <= rangeEnd) {
            return current;
        } else if(rangeStart > *current) {
            start = current+1;
        } else if(rangeEnd < *current) {
            end = current-1;
        }
    }

    return start;
}

void mexFunction(int num_out, mxArray *outParams[],
                 int num_in, const mxArray *inParams[]) {
    if(num_in != 5) {
        mexErrMsgIdAndTxt("Thesis:filter_windows_kdtree:num_in",
                          "4 Inputs required");
    }

    if(num_out < 1) {
        mexErrMsgIdAndTxt("Thesis:filter_windows_kdtree:num_out",
                          "1 Output required");
    }

    const mxArray* integral = inParams[0];
    const mxArray *tree;
    int xfield, yfield;

    if(!mxIsStruct(integral) || !mxIsDouble(inParams[1]) ||
       !mxIsDouble(inParams[2]) || !mxIsScalar(inParams[3]) || !mxIsScalar(inParams[4])) {
        mexErrMsgIdAndTxt("Thesis:filter_windows_kdtree:invalid_datatype",
                          "Param datatypes: (struct, double-matrix, double-vector, double-scalar, double-scalar)");
    }

    if(!(tree = mxGetField(integral, 0, "tree")) ||
         -1 == (xfield = mxGetFieldNumber(tree, "x")) ||
         -1 == (yfield = mxGetFieldNumber(tree, "y"))) {
        mexErrMsgIdAndTxt("Thesis:filter_windows_kdtree:invalid_integral",
                          "Field(s) tree.x or/and tree.y missing");
    }

    if(mxGetM(inParams[1]) != 4) {
        mexErrMsgIdAndTxt("Thesis:filter_windows_kdtree:invalid_window_matrix",
                          "Windows must be a 4xN matrix");
    }

    if(mxGetN(inParams[2]) != 1 && mxGetM(inParams[2]) != 1 ) {
        mexErrMsgIdAndTxt("Thesis:filter_windows_kdtree:invalid_dimension_list",
                          "Dimension list must be a vector");
    }

    size_t numWindows = mxGetN(inParams[1]);
    size_t numDimensions = mxGetNumberOfElements(inParams[2]);
    double numParts_d = mxGetScalar(inParams[3]);
    size_t numParts = static_cast<size_t>(numParts_d);
    double *windows = mxGetPr(inParams[1]);
    double *relevant_dimensions = mxGetPr(inParams[2]);
    size_t codebookSize = static_cast<size_t>(mxGetScalar(inParams[4]));
    //
    //double *outWindows = new double[numDimensions * 4];
    size_t numRemaining = 0;
    //printf("%d: %f, %f, %f, %f\n", numWindows, windows[0], windows[1], windows[2], windows[3]);

    if(numParts_d != numParts) {
        //printf("%f vs %d\n", numParts_d, numParts);
        mexErrMsgIdAndTxt("Thesis:filter_windows_kdtree:num_parts_frac",
                          "Number of parts must not be a fraction");
    }
    size_t *votes = reinterpret_cast<size_t*>(mxCalloc(numWindows, sizeof(size_t)));



    mxArray* x, *y;
    size_t numx, numy, from, to;
    uint32_t *x_lookup, *current;
    double *y_lookup;
    uint32_t minX, maxX;
    double minY, maxY;
    if(numParts == 1) {
        for(size_t d = 0; d < numDimensions; d++) {
            size_t dim = relevant_dimensions[d];
            //printf("Dimension %d\n", dim);
            x = mxGetFieldByNumber(tree, dim-1, xfield);
            if(!x || mxIsEmpty(x))
                continue;
            x_lookup = reinterpret_cast<uint32_t*>(mxGetPr(x));
            numx = mxGetM(x);
            //printf("%dx%d\n", numx, mxGetN(x));
            for(size_t i = 0; i < numWindows; i++) {
                minX = static_cast<uint32_t>(windows[i*4 + 0]);
                maxX = static_cast<uint32_t>(windows[i*4 + 2]);
                if((current = binsearch(x_lookup, x_lookup+numx-1, minX, maxX)) != nullptr) {
                    minY = windows[i*4 + 1];
                    maxY = windows[i*4 + 3];
                    y = mxGetFieldByNumber(tree, dim-1, yfield);
                    if(!y)
                        continue;
                    y_lookup = mxGetPr(y);
                    //numx = mxGetM(y);
                    from = static_cast<size_t>(current[numx]-1);
                    to = static_cast<size_t>(current[numx*2]-1);
                    if(binsearch(y_lookup+from, y_lookup+to, minY, maxY) != nullptr) {
                        votes[i]++;
                        if(votes[i] == numDimensions) {
                            numRemaining++;
                        }
                    }
                }
            }
        }
    } else {
        double partSqrt = sqrt(numParts);
        size_t xParts = static_cast<size_t>(round(partSqrt));
        size_t yParts = static_cast<size_t>(ceil(partSqrt));
        size_t part = 0;
        for(size_t d = 0; d < numDimensions; d++) {
            size_t dim = relevant_dimensions[d];
            //printf("Dimension %d\n", dim);
            part = dim / codebookSize;
            dim %= codebookSize;
            x = mxGetFieldByNumber(tree, dim-1, xfield);
            if(!x || mxIsEmpty(x))
                continue;
            x_lookup = reinterpret_cast<uint32_t*>(mxGetPr(x));
            numx = mxGetM(x);
            //printf("%dx%d\n", numx, mxGetN(x));
            for(size_t i = 0; i < numWindows; i++) {
                minX = static_cast<uint32_t>(windows[i*4 + 0]);
                maxX = static_cast<uint32_t>(windows[i*4 + 2]);
                minX = minX + (part % xParts) * (maxX - minX) / xParts;
                maxX = minX + ((part+1) % xParts) * (maxX - minX) / xParts;
                if((current = binsearch(x_lookup, x_lookup+numx-1, minX, maxX)) != nullptr) {
                    minY = windows[i*4 + 1];
                    maxY = windows[i*4 + 3];
                    minY = minY + (part / xParts) * (maxY - minY) / yParts;
                    maxY = minY + ((part+1) / xParts) * (maxY - minY) / yParts;
                    y = mxGetFieldByNumber(tree, dim-1, yfield);
                    if(!y)
                        continue;
                    y_lookup = mxGetPr(y);
                    //numx = mxGetM(y);
                    from = static_cast<size_t>(*(current+numx)-1);
                    to = static_cast<size_t>(*(current+numx*2)-1);
                    if(binsearch(y_lookup+from, y_lookup+to, minY, maxY) != nullptr) {
                        votes[i]++;
                        if(votes[i] == numDimensions) {
                            numRemaining++;
                        }
                    }
                }
            }
        }
    }
    printf("%4d/%04d Remaining\n", numRemaining, numWindows);

    outParams[0] = mxCreateDoubleMatrix(4, numRemaining, mxREAL);
    mxLogical* outFilter = 0;
    if(num_out == 2) {
        outParams[1] = mxCreateLogicalMatrix(1, numWindows);
        outFilter = reinterpret_cast<mxLogical*>(mxGetPr(outParams[1]));
    }
    if(numRemaining) {
        double* outWindows = mxGetPr(outParams[0]);
        size_t j = 0;
        for(size_t i = 0; i < numWindows; i++) {
            if(votes[i] == numDimensions) {
                memcpy(outWindows+4*j, windows+i*4, sizeof(double)*4);
                j++;
                if(outFilter) outFilter[i] = true;
            }
        }
    }
    mxFree(votes);
}

bool mxIsScalar(const mxArray *array_ptr) {
    return mxGetM(array_ptr) == mxGetN(array_ptr) == 1;
}
