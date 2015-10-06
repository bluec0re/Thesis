function codebook = sparse_codebook(integral, queryX, queryY)
%SPARSE_CODEBOOK calculates a codebook entry from a kd-Tee based integral image
%
%   Syntax:     codebook = sparse_codebook(integral, queryX, queryY)
%
%   Input:
%       integral - integral struct with fields tree.x and tree.y. Scores must
%                  not be summed up beforehand.
%       queryX, queryY - requested coordinates
%
%   Output:
%       codebook - Codebook vector
