function outmatrix = reconstruct_matrix_by_overwrite(integral)
%RECONSTRUCT_MATRIX_BY_OVERWRITE reconstructs a given sparse matrix into a full integral image
%
%   Syntax:     outmatrix = reconstruct_matrix_by_overwrite(integral)
%
%   Input:
%       integral - integral struct with fields scores, coords, I_size
%
%   Output:
%       outmatrix - Expanded integral matrix
