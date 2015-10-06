function codebook = sparse_codebook_integral(integral, x, y)
%SPARSE_CODEBOOK_INTEGRAL calculates a codebook entry from a kd-Tee based integral image
%
%   Syntax:     codebook = sparse_codebook_integral(integral, queryX, queryY)
%
%   Input:
%       integral - integral struct with fields tree.x and tree.y. Scores must
%                  not be summed up beforehand.
%       x, y     - x and y coordinates (2 elements per vector)
%
%   Output:
%       codebook - Codebook vector
