#include "calc_codebook.h"

// #undef eprintf
// #define eprintf(...) {if(i == 47)fprintf(stderr, __VA_ARGS__);}

void calc_codebook(const mxArray *tree, int xfield, int yfield, uint32_t queryX, uint32_t queryY, double *codebook, int cbs) {
    const mxArray *x, *y;
    uint32_t *x_lookup, *idx;
    double *y_lookup, *idy;
    int i=47;
    //int j=0;
    size_t numy, numx;
    uint32_t from, to;

    eprintf("Query: (%u, %u)\n", queryX, queryY);

    for(i = 0; i < cbs; i++) {
        eprintf("Dim: %d\n", i+1);
        x = mxGetFieldByNumber(tree, i, xfield);
        //x = mxGetField(tree, i, "x");
        eprintf("x: %p\n", (void*)x);


        if(x && !mxIsEmpty(x)) {
            //j++;
#if 0
            if(!mxIsUint32(x)) {
                mexErrMsgIdAndTxt("Thesis:sparse_codebook:invalid_x_lookup",
                                  "tree.x should be uint32_t");
            }
#endif

            x_lookup = (uint32_t*)mxGetPr(x);
            numx = mxGetM(x);
            eprintf("#X: %d\n", numx);
            //numx--;
            eprintf("x(1, 1): %p = %u\n", (void*)x_lookup, x_lookup[0]);
            eprintf("x(1, 2): %p = %u\n", (void*)&x_lookup[numx], x_lookup[numx]);
            eprintf("x(1, 3): %p = %u\n", (void*)&x_lookup[numx*2], x_lookup[numx*2]);
            eprintf("x(2, 1): %p = %u\n", (void*)&x_lookup[1], x_lookup[1]);
            eprintf("x(2, 2): %p = %u\n", (void*)&x_lookup[1+numx], x_lookup[1+numx]);
            eprintf("x(2, 3): %p = %u\n", (void*)&x_lookup[1+numx*2], x_lookup[1+numx*2]);
            eprintf("x(3, 1): %p = %u\n", (void*)&x_lookup[2], x_lookup[2]);
            eprintf("x(3, 2): %p = %u\n", (void*)&x_lookup[2+numx], x_lookup[2+numx]);
            eprintf("x(3, 3): %p = %u\n", (void*)&x_lookup[2+numx*2], x_lookup[2+numx*2]);
            eprintf("x(end, 1): %p = %u\n", (void*)(&x_lookup[numx]), x_lookup[numx]);
            idx = kd_tree_find_lower<uint32_t>(x_lookup, &x_lookup[numx-1], queryX);
            eprintf("idx: %p", (void*)idx);
            if(idx) {
                eprintf(" = %u\n", *idx);
                from = idx[numx] - 1;
                to = idx[numx*2] - 1;

                y = mxGetFieldByNumber(tree, i, yfield);
                y_lookup = mxGetPr(y);
                eprintf("%u (%f) - %u (%f)\n", from, to, y_lookup[from], y_lookup[to]);
                idy = kd_tree_find_lower<double>(&y_lookup[from], &y_lookup[to], queryY);
                eprintf("idy: %p", (void*)idy);
                if(idy) {
                    eprintf(" = %f\n", *idy);
                    numy = mxGetM(y);
                    eprintf("#Y: %d\n", numy);
                    //numy--;
                    codebook[i] = idy[numy];
                }
            }
        }
    }
    //eprintf("%d x lookup tables found\n", j);
}
