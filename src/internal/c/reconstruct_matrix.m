function outmatrix = reconstruct_matrix(inmatrix)
%RECONSTRUCT_MATRIX reconstructs a given sparse matrix into a full integral image
%
%   Syntax:     outmatrix = reconstruct_matrix(inmatrix)
%
%   Input:
%       inmatrix - DxWxH Matrix with changed cells filled, everything else 0
%
%   Output:
%       outmatrix - The same matrix but expanded into a integral matrix.
%                   Input matrix is reused for speed
