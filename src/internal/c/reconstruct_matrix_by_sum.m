function outmatrix = reconstruct_matrix_by_sum(integral)
%RECONSTRUCT_MATRIX_BY_SUM reconstructs a given sparse matrix into a full integral image
%
%   Syntax:     outmatrix = reconstruct_matrix_by_sum(integral)
%
%   Input:
%       integral - integral struct with fields scores, coords, I_size. Scores must
%                  not be summed up beforehand.
%
%   Output:
%       outmatrix - Expanded integral matrix
