
#default: sparse_codebook_integral.mexa64
default: all

all: sparse_codebook_integral.mexa64 sparse_codebook.mexa64 sparse_codebook_old.mexa64 reconstruct_matrix.mexa64 reconstruct_matrix_by_sum.mexa64 reconstruct_matrix_by_overwrite.mexa64 filter_windows_kdtree.mexa64

sparse_codebook.mexa64: sparse_codebook.o calc_codebook.o
	mex $+ -O

sparse_codebook_integral.mexa64: sparse_codebook_integral.o calc_codebook.o
	mex $+ -O

sparse_codebook_old.mexa64: sparse_codebook_old.c
	mex $+ -O

reconstruct_matrix.mexa64: reconstruct_matrix.c
	mex $+ -O

reconstruct_matrix_by_sum.mexa64: reconstruct_matrix_by_sum.c
	mex $+ -g

reconstruct_matrix_by_overwrite.mexa64: reconstruct_matrix_by_overwrite.o
	mex $+ -g

calc_codebook.o: calc_codebook.cpp calc_codebook.h
	mex -c -O calc_codebook.cpp

%.o: %.cpp
	mex -c -O $?

%.o: %.c
	mex -c -O $?

%.mexa64: %.o
	mex $+ -O

clean:
	@rm -f *.mexa64 *.o

.PHONY: clean
