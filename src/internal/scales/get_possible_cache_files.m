function files = get_possible_cache_files(cachename)
%GET_ Summary of this function goes here
%   Detailed explanation goes here

    files = strsplit(strtrim(ls(strrep(cachename, '%d', '*'), '-1')), '\n');
end

