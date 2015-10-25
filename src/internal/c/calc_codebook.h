#ifndef SPARSE_CODEBOOK_HEADER
#define SPARSE_CODEBOOK_HEADER

#include <stdint.h>
#include "mex.h"


#if 0
    #define eprintf(...) fprintf(stderr, __VA_ARGS__)
#else
    #define eprintf(...)
#endif

template<class T>
T* kd_tree_find_lower_(T* lower, T* upper, uint32_t value) {
    if(lower > upper) {
        mexErrMsgIdAndTxt("Thesis:calc_codebook:internal_error",
                          "lower > upper");
    }
    //eprintf("From: %p To: %p\n", lower, upper);
    uint32_t curval = *lower;
    if(curval > value)
        return 0;
    if(curval == value)
        return lower;
    if(*upper <= value)
        return upper;

    size_t idx, l = 0, u = (upper - lower);

    eprintf("%u: %p=%f ", l, &lower[l], lower[l]);
    eprintf(" %u: %p=%f\n", u, &lower[u], lower[u]);
    while(l < u) {
        idx = (l+u) / 2;
        curval = lower[idx];

        if(curval == value) {
            return &lower[idx];
        } else if(curval < value) {
            l = idx;
        } else {
            u = idx;
        }

        eprintf("%u: %p=%f ", l, &lower[l], lower[l]);
        eprintf(" %u: %p=%f\n", u, &lower[u], lower[u]);

        if((u - l) == 1) {
            if(lower[l] < value) {
                if(value < lower[u])
                    return &lower[l];
                if(lower[u] < value	)
                    return &lower[u];
            }
            return 0;
        }
    }

    return &lower[u];
}

template<class T>
T* kd_tree_find_lower(T* lower, T* upper, uint32_t value) {
    if(lower > upper) {
        mexErrMsgIdAndTxt("Thesis:calc_codebook:internal_error",
                          "lower > upper");
    }
    //eprintf("From: %p To: %p\n", lower, upper);
    uint32_t curval = *lower;
    if(curval > value)
        return 0;
    if(curval == value)
        return lower;
    if(*upper <= value)
        return upper;

    T* idx;

    eprintf("%p=%f ", lower, *lower);
    eprintf(" %p=%f\n", upper, *upper);
    while(lower < upper) {
        idx = lower + (upper - lower) / 2;
        curval = *idx;

        if(curval == value) {
            return idx;
        } else if(curval < value) {
            lower = idx;
        } else {
            upper = idx;
        }

        eprintf("%p=%f ", lower, *lower);
        eprintf(" %p=%f\n", upper, *upper);

        if((upper - lower) == 1) {
            if(*lower < value) {
                if(value < *upper)
                    return lower;
                else
                    return upper;
            }
            return 0;
        }
    }

    return upper;
}

void calc_codebook(const mxArray *tree, int xfield, int yfield, uint32_t queryX, uint32_t queryY, double *codebook, int cbs);

#endif
