#ifndef SPARSE_CODEBOOK_HEADER
#define SPARSE_CODEBOOK_HEADER

#include <stdint.h>
#include "mex.h"


#if 0
    #define eprintf(...) fprintf(stderr, __VA_ARGS__)
#else
    #define eprintf(...)
#endif

void calc_codebook(const mxArray *tree, int xfield, int yfield, uint32_t queryX, uint32_t queryY, double *codebook, int cbs);

#endif
