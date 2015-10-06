function files = get_possible_cache_files(cachename)
%GET_POSSIBLE_CACHE_FILES get all possible cache files based on a format string
%
%   Syntax:     files = get_possible_cache_files(cachename)
%
%   Input:
%       cachename      - format string to search for. Replaces %d by *
%
%   Output:
%       files - list of possible files

    files = strsplit(strtrim(ls(strrep(cachename, '%d', '*'), '-1')), '\n');
end
