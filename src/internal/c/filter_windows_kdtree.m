function filter = filter_windows_kdtree(tree, windows, dimensions, parts, codebooks)
%FILTER_WINDOWS_KDTREE Filters a list of windows based on the amount of codebook dimensions set
%
%   Syntax:     filter = filter_windows_kdtree(tree, windows, dimensions, parts, codebooks)
%
%   Input:
%       tree       - kd-Tree to use
%       windows    - 4xN window list
%       dimensions - vector of relevant codebook dimensions
%       parts      - Number of parts per window
%       codebooks  - Number of dimensions per codebook
%
%   Output:
%       filter     - Logical vector of remaining windows
